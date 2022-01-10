// TODO: rename method_'s to method__'s
(
var include_relative = { |relative_path|
	var path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ relative_path).standardizePath;
	if (File.exists(path)) {
		var result = this.executeFile(path);
		if (result.isNil) { Error("error importing %".format(path)).throw; } { result };
	} {
		Error("include_relative: file % does not exist".format(path.quote)).throw;
	};
};

var include_absolute = { |absolute_path|
	var path = absolute_path.standardizePath;
	if (File.exists(path)) {
		var result = this.executeFile(path);
		if (result.isNil) { Error("error importing %".format(path)).throw; } { result };
	} {
		Error("include_absolute: file % does not exist".format(path.quote)).throw;
	};
};

var include_engine_dependency = { |engine_name|
	var engine_root = engine_paths[engine_name.asSymbol][\absolute_path];
	if (File.exists(engine_root)) {
		include_absolute.value(engine_root +/+ "lib" +/+ (engine_name.asString ++ ".scd"));
	} {
		Error("include_engine_dependency: FAILED. expected engine % installed at %".format(engine_name, engine_root.quote)).throw; // TODO: ugly path
	};
};

var lookup_absolute_path = { |relative_path|
	(PathName(thisProcess.nowExecutingPath).pathOnly +/+ relative_path).standardizePath;
};

var engine_paths = (
	ack: (
		relative_path: ".." +/+ ".." +/+ ".." +/+ "ack"
	),
	r: (
		relative_path: ".." +/+ ".." +/+ ".." +/+ "r"
	),
).collect { |dict, engine_name| dict[\absolute_path] = lookup_absolute_path.value(dict[\relative_path])};

var namespaces = ();

var load_class_dynamically = { |classname|
	thisProcess.interpreter.interpret(classname.asString);
};

var class_exists = { |classname|
	Class.allClasses.collect { |class| class.asSymbol }.includes(classname.asSymbol);
};

namespaces.arc_device_manager = {
	// utility library to use a SerialOSCEnc to mock a norns enc, implementing a subset of functions.

	var init_arc_device_manager = { |script_env|
		var arc_device_manager = ();

		arc_device_manager['__enc_delta_funcs__'] = [];

		arc_device_manager.connect_ = { |self, n|
			if (class_exists.value('SerialOSCClient')) {
				var arc_device;
				var serialOSCEncClass = load_class_dynamically.value("SerialOSCEnc");
				var encDeltaFuncClass = load_class_dynamically.value("EncDeltaFunc");

				n = n ? 1;

				if (n != 1) {
					Error("multiple arcs are not supported").throw
				};

				arc_device = (
					ring0_map: Array.fill(64),
					ring1_map: Array.fill(64),
					ring2_map: Array.fill(64),
					ring3_map: Array.fill(64)
				);
				arc_device.led_ = { |self, ring, x, val|
					self[("ring"++(ring-1)++"_map").asSymbol][x-1] = val;
				};
				arc_device.all_ = { |self, val|
					4.do { |ring|
						64.do { |index|
							self[("ring"++ring++"_map").asSymbol][index] = val;
						};
					};
				};
				arc_device.refresh_ = { |self|
					serialOSCEncClass.default !? {
						serialOSCEncClass.ringMap(0, self[\ring0_map]);
						serialOSCEncClass.ringMap(1, self[\ring1_map]);
						if (serialOSCEncClass.numEncs == 4) {
							serialOSCEncClass.ringMap(2, self[\ring2_map]);
							serialOSCEncClass.ringMap(3, self[\ring3_map]);
						};
					};
				};

				arc_device_manager['__enc_delta_funcs__'] = arc_device_manager['__enc_delta_funcs__'].add(
					encDeltaFuncClass.new(
						{ |ring, n, delta|
							script_env.use {
								arc_device[\delta].value(ring+1, n+1, delta); // TODO: change to delta_, if possible without introducing self arg
							};
						}
					)
				);

				arc_device;
			} {
				"Arc usage is disabled. SerialOSCClient SuperCollider library is required. Download the library from http://github.com/antonhornquist/SerialOSCClient-sc.".inform;
				();
			};
		};
		arc_device_manager
	};

	var free_arc_device_manager = { |arc_device_manager|
		arc_device_manager['__enc_delta_funcs__'] do: _.free
	};

	var module = IdentityDictionary[
		\init_arc_device_manager -> init_arc_device_manager,
		\free_arc_device_manager -> free_arc_device_manager
	];

	module
}.value;

namespaces.midi_device_manager = {
	var init_midi_device_manager = { |script_env|
		var midi_device_manager = ();

		var route_incoming_midi_message = { |midi_device, message|
			script_env.use {
				if (~device_to_enc_key_mapper.handle_midi_(message).isNil) {
					midi_device[\event].value( // TODO: change to event_, if possible without introducing self arg
						message
					);
				}
			};
		};

		var midi_device;

		midi_device = ();

		midi_device.device_ = { |self|
			if (MIDIClient.sources.notEmpty or: MIDIClient.destinations.notEmpty) {
				MIDIClient
			}
		};

		MIDIIn.connectAll;

		midi_device_manager['__midi_funcs__'] = midi_device_manager['__midi_funcs__'].add(
			MIDIFunc.cc(
				{ |val, num, chan|
					route_incoming_midi_message.value(
						midi_device,
						(
							type: 'cc',
							val: val,
							num: num,
							chan: chan
						)
					);
				}
			)
		);

		midi_device_manager['__midi_funcs__'] = midi_device_manager['__midi_funcs__'].add(
			MIDIFunc.noteOn(
				{ |vel, note, chan|
					route_incoming_midi_message.value(
						midi_device,
						(
							type: 'note_on',
							vel: vel,
							note: note,
							chan: chan
						)
					);
				}
			)
		);

		midi_device_manager['__midi_funcs__'] = midi_device_manager['__midi_funcs__'].add(
			MIDIFunc.noteOff(
				{ |vel, note, chan|
					route_incoming_midi_message.value(
						midi_device,
						(
							type: 'note_off',
							vel: vel,
							note: note,
							chan: chan
						)
					);
				}
			)
		);

		midi_device_manager.connect_ = { |self, n|
			n = n ? 1;

			if (n != 1) {
				Error("multiple midi devices are not supported").throw
			};

/*
			TODO: midi_device out
			midi_device.send_ = { |self, data|
				MIDIOut....
			};
*/

			midi_device;
		};
		midi_device_manager.to_data_ = { |self, msg|
			msg // TODO
		};
		midi_device_manager.to_msg_ = { |self, data|
			data
		};
		midi_device_manager
	};

	var free_midi_device_manager = { |midi_device_manager|
		midi_device_manager['__midi_funcs__'] do: _.free;
	};

	var module = IdentityDictionary[
		\init_midi_device_manager -> init_midi_device_manager,
		\free_midi_device_manager -> free_midi_device_manager
	];

	module
}.value;

namespaces.grid_device_manager = {
	// utility library to use a SerialOSCGrid to mock a norns grid, implementing a subset of functions.

	var init_grid_device_manager = { |script_env|
		var grid_device_manager = ();

		grid_device_manager['__grid_key_funcs__'] = [];

		grid_device_manager.connect_ = {
			if (class_exists.value('SerialOSCClient')) {
				var grid_device;
				var serialOSCGridClass = load_class_dynamically.value("SerialOSCGrid");
				var gridKeyFuncClass = load_class_dynamically.value("GridKeyFunc");

				n = n ? 1;

				if (n != 1) {
					Error("multiple grids are not supported").throw
				};

				grid_device = (
					topleft_map: Array.fill(64),
					topright_map: Array.fill(64),
					bottomleft_map: Array.fill(64),
					bottomright_map: Array.fill(64)
				);
				grid_device.led_ = { |self, x, y, val|
					if ((x < 9) and: (y < 9)) {
						self[\topleft_map][((y-1)*8)+(x-1)] = val;
					};
					if ((x >= 9) and: (y < 9)) {
						self[\topright_map][((y-1)*8)+(x-1-8)] = val;
					};
					if ((x < 9) and: (y >= 9)) {
						self[\bottomleft_map][((y-1-8)*8)+(x-1)] = val;
					};
					if ((x >= 9) and: (y >= 9)) {
						self[\bottomright_map][((y-1-8)*8)+(x-1-8)] = val;
					};
				};
				grid_device.all_ = { |self, val|
					64.do { |index|
						self[\topleft_map][index] = val;
						self[\topright_map][index] = val;
						self[\bottomleft_map][index] = val;
						self[\bottomright_map][index] = val;
					};
				};
				grid_device.cols_ = { |self|
					serialOSCGridClass.numCols;
				};
				grid_device.rows_ = { |self|
					serialOSCGridClass.numRows;
				};
				grid_device.device_ = { |self|
					serialOSCGridClass.default;
				};
				grid_device.refresh_ = { |self|
					serialOSCGridClass.default !? {
						var num_cols = serialOSCGridClass.numCols;
						var num_rows = serialOSCGridClass.numRows;
						serialOSCGridClass.ledLevelMap(0, 0, self[\topleft_map]);
						if (num_cols == 16) {
							serialOSCGridClass.ledLevelMap(8, 0, self[\topright_map]);
						};
						if (num_rows == 16) {
							serialOSCGridClass.ledLevelMap(0, 8, self[\bottomleft_map]);
						};
						if ((num_cols == 16) and: (num_rows == 16)) {
							serialOSCGridClass.ledLevelMap(8, 8, self[\bottomright_map]);
						};
					};
				};

				grid_device_manager['__grid_key_funcs__'] = grid_device_manager['__grid_key_funcs__'].add(
					gridKeyFuncClass.new(
						{ |x, y, state|
							script_env.use {
								grid_device[\key].value(x+1, y+1, state); // TODO: change to key_, if possible without introducing self arg
							};
						}
					)
				);

				grid_device;
			} {
				"Grid usage is disabled. SerialOSCClient SuperCollider library is required. Download the library from http://github.com/antonhornquist/SerialOSCClient-sc.".inform;
				();
			};
		};
		grid_device_manager;
	};

	var free_grid_device_manager = { |grid_device_manager|
		grid_device_manager['__grid_key_funcs__'] do: _.free;
	};

	var module = IdentityDictionary[
		\init_grid_device_manager -> init_grid_device_manager,
		\free_grid_device_manager -> free_grid_device_manager
	];

	module
}.value;

namespaces.poll_manager = {
	var init_poll_manager = { |engine_polls|
		var poll_manager = ();

		poll_manager['__polls__'] = [];
		poll_manager.set__ = { |self, name, callback|
			var engine_poll = engine_polls.detect { |engine_poll|
				engine_poll.key == name.asSymbol
			};

			if (engine_poll.notNil) {
				var engine_poll_content = engine_poll.value;
				var engine_poll_func = engine_poll_content[\func];
				var engine_poll_time = engine_poll_content[\time];
				var new_poll;

				new_poll = ();
				new_poll[\is_running_] = false;
				new_poll.time_ = engine_poll_time ? 0.25;
				new_poll.action_ = callback;

				new_poll.start_ = { |self|
					if (self[\is_running_].not) {
						self.task_ = Task {
							inf.do {
								self[\action_].value(engine_poll_func.value); // TODO: wrap in Environment.use
								self.time_.wait;
							}
						}.play;
						self[\is_running_] = true;
						// "poll started".inform;
					} {
						"poll already started".inform;
					};
				};
				new_poll.stop_ = { |self|
					if (self[\is_running_]) {
						self.task_.stop;
						self[\is_running_] = false;
						// "poll stopped".inform;
					} {
						"poll already stopped".inform;
					};
				};
				new_poll.free_ = { |self|
					self.stop_();
					self['__polls__'].remove(self);
				};
				new_poll.update_ = { |self|
					{
						self[\action_].value(engine_poll_func.value);
					}.fork;
				};

				self['__polls__'] = self['__polls__'].add(new_poll);

				new_poll;
			} {
				Error("no poll called %".format(name)).throw;
			};
		};

		poll_manager.free_all_ = { |self|
			self['__polls__'].copy.do { |poll|
				poll.free_();
			};
		};

		poll_manager;
	};

	var free_poll_manager = { |poll_manager|
		// TODO poll_manager['__polls__'].do { |poll| poll.free_() };
		poll_manager.free_all_();
	};

	var module = IdentityDictionary[
		\init_poll_manager -> init_poll_manager,
		\free_poll_manager -> free_poll_manager
	];

	module;
}.value;

namespaces.metro_manager = {
	var init_metro_manager = {
		var metro_manager = ();

		metro_manager['__metros__'] = [];
		metro_manager.init_ = { |self, config|
			var event = config !? _.event;
			var time = (config !? _.time) ? 1;
			var count = (config !? _.count) ? inf;
			var new_metro;

			new_metro = ();
			new_metro[\event] = event;
			new_metro[\time] = time;
			new_metro[\count] = count;
			new_metro[\id] = self['__metros__'].size;
			new_metro[\is_running] = false;
			new_metro.start_ = { |self, time, count|
				if (time.notNil) {
					self[\time] = time;
				};
				if (count.notNil) {
					self[\count] = count;
				};
				self[\routine].stop;
				self[\routine] = fork {
					self[\count].do {
						self[\event].value;
						self[\time].wait;
					}
				}
			};
			new_metro.stop_ = { |self|
				self[\routine].stop;
			};
			new_metro.free_ = { |self|
				self.stop_();
				self['__metros__'].remove(self);
			};

			self['__metros__'] = self['__metros__'].add(new_metro);

			new_metro;
		};

		metro_manager.free_all_ = { |self|
			self['__metros__'].copy.do { |metro|
				metro.free_();
			};
		};

		metro_manager;
	};

	var free_metro_manager = { |metro_manager|
		metro_manager.free_all_();
	};

	var module = IdentityDictionary[
		\init_metro_manager -> init_metro_manager,
		\free_metro_manager -> free_metro_manager
	];

	module;
}.value;

namespaces.screen = { // TODO: call this mock_screen?
	// utility library to mock a UserView as a norns screen, drawable with a limited subset of norns screen functions. uses 1 based coordinates. uses global ~screen global for storage of relevant objects (not functions). relies on global ~redraw function wherein screen_* commands are performed.

	var screen_width = 128;
	var screen_height = 64;
	var default_font_size = 8;

	var default_background_color = Color.black;
	var default_foreground_color = Color.white;

/*
	TODO
	var num_levels = 16;
	var colors = num_levels.collect { |level|
		background_color.blend(foreground_color, level/(num_levels-1));
	};
*/

	var default_colors = [0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 1].collect { |level| default_background_color.blend(default_foreground_color, level) };

	var screen_init = { |parent_view, x_pos, y_pos, scale, colors|
		var background_color = (colors ? default_colors)[0]; 
		var instance = (
			view: UserView(parent_view, Rect(x_pos, y_pos, round(screen_width*scale), round(screen_height*scale)))
				.background_(background_color)
				.drawFunc_({
					instance[\queued_screen_ops].do { |screen_op|
						screen_op.value;
					};
					instance[\queued_screen_ops] = [];
				})
				.canReceiveDragHandler_({true})
				.clearOnRefresh_(false),
			font_size: default_font_size,
			font: Font(lookup_font.value, calculate_scaled_font_size.value(scale, default_font_size)),
			position: 1@1,
			scale: scale,
			colors: colors ? default_colors,
			level: 15,
			queued_screen_ops: []
		);
		instance;
	};

	var screen_level = { |instance, level|
		instance[\level] = level;
	};

	var screen_rect = { |instance, x_pos, y_pos, width, height|
		var scale = instance[\scale];

		// start
		x_pos = round(x_pos);
		y_pos = round(y_pos);
		width = round(width);
		height = round(height);
		// fin

		x_pos = x_pos - 1;
		y_pos = y_pos - 1;

		instance[\queued_screen_ops] = instance[\queued_screen_ops].add(
			{
				Pen.addRect(Rect(round(scale * x_pos), round(scale * y_pos), round(scale * width), round(scale * height)));
			}
		);
	};

	var screen_move = { |instance, x_pos, y_pos|
		var scale = instance[\scale];

		// start
		x_pos = round(x_pos);
		y_pos = round(y_pos);
		// fin

		instance[\position] = x_pos@y_pos;
		x_pos = x_pos - 1;
		y_pos = y_pos - 1;
		instance[\queued_screen_ops] = instance[\queued_screen_ops].add(
			{
				Pen.moveTo(round(scale * x_pos)@round(scale * y_pos)); // TODO: offset here?
			}
		);
	};

	var screen_line = { |instance, to_x, to_y|
		var scale = instance[\scale];
		var level = instance[\level];
		var position = instance[\position];
		var offset = scale/2;
		var from_x = round(scale * (position.x - 1))+offset;
		var from_y = round(scale * (position.y - 1))+offset;

		// start
		to_x = round(to_x);
		to_y = round(to_y);
		// fin

		to_x = round(scale * (to_x - 1))+offset;
		to_y = round(scale * (to_y - 1))+offset;
		instance[\queued_screen_ops] = instance[\queued_screen_ops].add(
			{
				Pen.moveTo(from_x@from_y);
				Pen.width = scale;
				Pen.lineTo(to_x@to_y);
			}
		);
	};

	var screen_line_rel = { |instance, to_x_rel, to_y_rel|
		var scale = instance[\scale];
		var level = instance[\level];
		var position = instance[\position];
		var offset = scale/2;
		var from_x = round(scale * (position.x - 1))+offset;
		var from_y = round(scale * (position.y - 1))+offset;
		var to_x;
		var to_y;

		// start
		to_x_rel = round(to_x_rel);
		to_y_rel = round(to_y_rel);
		// fin

		to_x = round(scale * (position.x + to_x_rel - 1))+offset;
		to_y = round(scale * (position.y + to_y_rel - 1))+offset;

		instance[\queued_screen_ops] = instance[\queued_screen_ops].add(
			{
				Pen.moveTo(from_x@from_y);
				Pen.width = scale;
				Pen.lineTo(to_x@to_y);
			}
		);
	};

	var screen_stroke = { |instance|
		var scale = instance[\scale];
		var level = instance[\level];
		var color = instance[\colors][level];
		instance[\queued_screen_ops] = instance[\queued_screen_ops].add(
			{
				Pen.strokeColor = color;
				Pen.width = scale;
				Pen.stroke;
			}
		);
	};

	var screen_text = { |instance, text|
		var scale = instance[\scale];
		var position = instance[\position];
		var level = instance[\level];
		var color = instance[\colors][level];

		var x_pos = position.x - 1;
		var y_pos = position.y - 1;

		y_pos = y_pos - (instance[\font_size] * 0.8);

		text = text.asString;

		instance[\queued_screen_ops] = instance[\queued_screen_ops].add(
			{
				Pen.font = instance[\font];
				Pen.color = color;
				Pen.stringAtPoint(text, round(scale * x_pos)@round(scale * y_pos));
			}
		);
	};

	var screen_text_right = { |instance, text|
		var scale = instance[\scale];
		var position = instance[\position];
		var level = instance[\level];
		var color = instance[\colors][level];

		var x_pos = position.x - 1;
		var y_pos = position.y - 1;

		y_pos = y_pos - (instance[\font_size] * 0.8);

		text = text.asString;

		instance[\queued_screen_ops] = instance[\queued_screen_ops].add(
			{
				Pen.font = instance[\font];
				Pen.color = color;
				Pen.stringRightJustIn(text, Rect.newSides(0, round(scale * y_pos), round(scale * x_pos), round(scale * y_pos)+(instance[\font_size]*scale)));
			}
		);
	};

	var screen_font_size = { |instance, font_size|
		var scale = instance[\scale];
		instance[\font_size] = font_size;
		instance[\font].size = calculate_scaled_font_size.value(scale, font_size);
	};

	var screen_text_extents = { |instance, text|
		var scale = instance[\scale];
		var font = instance[\font];
		(text.bounds(font).width)/scale;
	};

	var screen_fill = { |instance|
		var level = instance[\level];
		var color = instance[\colors][level];
		instance[\queued_screen_ops] = instance[\queued_screen_ops].add(
			{
				Pen.fillColor = color;
				Pen.fill;
			}
		);
	};

	var screen_clear = { |instance|
		var scale = instance[\scale];
		var view = instance[\view];
		var background_color = instance[\colors][0];
		instance[\queued_screen_ops] = instance[\queued_screen_ops].add(
			{
				var width = view.bounds.width;
				var height = view.bounds.height;
				var x_pos = 0;
				var y_pos = 0;
				Pen.addRect(Rect(round(scale * x_pos), round(scale * y_pos), round(scale * width), round(scale * height)));
				Pen.fillColor = background_color;
				Pen.fill;
			}
		);
	};

	var screen_update = { |instance|
		defer {
			instance[\view].refresh;
		}
	};

	var calculate_scaled_font_size = { |scale, unscaled_font_size|
		round(unscaled_font_size * scale * 13 / 16) // TODO: ideal font size
	};

	var lookup_font = {
		Font.defaultSansFace
	};

	var init_screen = { |parent_view, x, y, scale|
		var screen_instance = screen_init.value(parent_view, x, y, scale);
		var screen = ();

		screen.rect_ = { |self, x, y, width, height|
			screen_rect.value(screen_instance, x, y, width, height);
		};
		screen.move_ = { |self, x, y|
			screen_move.value(screen_instance, x, y);
		};
		screen.line_ = { |self, x, y|
			screen_line.value(screen_instance, x, y);
		};
		screen.line_rel_ = { |self, x, y|
			screen_line_rel.value(screen_instance, x, y);
		};
		screen.stroke_ = { |self|
			screen_stroke.value(screen_instance);
		};
		screen.fill_ = { |self|
			screen_fill.value(screen_instance);
		};
		screen.level_ ={ |self, level|
			screen_level.value(screen_instance, level);
		};
		screen.text_ = { |self, text|
			screen_text.value(screen_instance, text);
		};
		screen.text_right_ = { |self, text|
			screen_text_right.value(screen_instance, text);
		};
		screen.text_extents_ = { |self, text|
			screen_text_extents.value(screen_instance, text);
		};
		screen.font_size_ = { |self, size|
			screen_font_size.value(screen_instance, size);
		};
		screen.clear_ = { |self|
			screen_clear.value(screen_instance);
		};
		screen.update_ = { |self|
			screen_update.value(screen_instance);
		};

		(
			singleton: screen,
			view: screen_instance[\view]
		);
	};

	var module = IdentityDictionary[
		\init_screen -> init_screen
	];

	module
}.value;

namespaces.paramset = {
	var init_paramset = { |script_env|
		var paramset = (
			name: "unnamed",
			params: [],
			count: 0
		);

		paramset.add_separator_ = { |self|
			var param;
			param = ();
			param[\type] = \separator;
			self[\params] = self[\params].add(param);
		};
		paramset.add_ = { |self, arg_param|
			var type = arg_param[\type].asSymbol;
			var id = arg_param[\id].asSymbol;
			var name = arg_param[\name];
			var action = arg_param[\action];
			var param;

			if (['file', 'control', 'number', 'option'].includes(type).not) {
				Error("only params of type 'file', 'control', 'number' and 'option' are supported").throw;
			};

			param = ();

			param[\type] = type;
			param[\id] = id;
			param[\name] = name;

			case
			{ type == 'file' } {
				param[\path] = "-";
				param[\action] = action;
				param.get_ = { |self|
					self[\path];
				};
				param.set__ = { |self, value, silent| // TODO: set__
					value = value.asString;
					if (self[\path] != value) {
						self[\path] = value;
					};
					if (silent.asBoolean.not) {
						self.bang_();
					}
				};
				param.string_ = { |self|
					PathName(self[\path]).fileName
				};
				param.bang_ = { |self|
					self[\action].value(self[\path]);
				};
			}
			{ type == 'control' } {
				var controlspec = arg_param[\controlspec].asSpec;
				var formatter = arg_param[\formatter];
				param[\controlspec] = controlspec;
				param[\action] = action;
				param[\formatter] = formatter;
				param[\raw] = if (controlspec.default.notNil) { controlspec.unmap(controlspec.default) } { 0 };
				param.get_ = { |self| // TODO
					self[\controlspec].map(self[\raw])
				};
				param.get_raw_ = { |self|
					self[\raw];
				};
				param.set__ = { |self, value|
					self.set_raw_(self[\controlspec].unmap(value.asFloat));
				};
				param.set_raw_ = { |self, value|
					self[\raw] = value.clip(0, 1);
					self[\action].value(self[\controlspec].map(self[\raw]));
				};
				param.delta_ = { |self, delta|
					self.set_raw_(self[\raw] + (delta/100));
				};
				param.string_ = { |self|
					if (self[\formatter].notNil) {
						self[\formatter].value(self);
					} {
						round(self.get_(), 0.01).asString ++ " " ++ (self[\controlspec].units ?? "")
					};
				};
				param.bang_ = { |self|
					self[\action].value(self.get_());
				};
			}
			{ type == 'option' } {
				var options = arg_param[\options];
				var default = arg_param[\default];
				param[\options] = options;
				param[\action] = action;
				param[\selected] = default ? 1;
				param.get_ = { |self|
					self[\selected]
				};
				param.set__ = { |self, value, silent|
/*
	TODO
  local silent = silent or false
  local c = util.clamp(math.floor(v),1,self.count)
  if self.selected ~= c then
    self.selected = c
    if silent==false then self:bang() end
  end
*/
					self[\selected] = value.asInteger.clip(1, param[\options].size); // TODO: constrain to options
					if (silent.asBoolean.not) {
						self[\action].value(self[\selected]);
					}
				};
				param.delta_ = { |self, delta|
/*
	TODO
  if d<0 then d = math.floor(d)
  else d = math.ceil(d) end
  self:set(self:get() + d)
*/
					self.set__(self.get_() + delta);
				};
				param.string_ = { |self|
					self[\options][self[\selected]-1].asString
				};
				param.bang_ = { |self|
					self[\action].value(self[\selected]);
				};
			}
			{ type == 'number' } {
				var min_ = arg_param[\min];
				var max_ = arg_param[\max];
				var default_ = arg_param[\default];
				var formatter = arg_param[\formatter];
				param[\min] = min_;
				param[\max] = max_;
				param[\default] = default_ ? 0;
				param[\value] = param[\default];
				param[\action] = action;
				param[\formatter] = formatter;
				param.get_ = { |self|
					self[\value]
				};
				param.string_ = { |self|
					if (self[\formatter].notNil) {
						self[\formatter].value(self);
					} {
						self[\value]
					};
				};
				param.set__ = { |self, value|
					self[\value] = (value.asInteger min: self[\max]) max: self[\min]; // TODO: constrain to number spec
				};
				param.delta_ = { |self, delta|
					self.set__(self.get_() + delta);
				};
				param.bang_ = { |self|
					self[\action].value(self[\value]);
				};
			};

			self[\params] = self[\params].add(param);
			self[\count] = self[\count] + 1;
		};
		paramset.lookup_param_ = { |self, id|
			self[\params].detect { |param| param[\id] == id.asSymbol };
		};
		paramset.get_name_ = { |self, id|
			var param = self.lookup_param_(id);
			param[\name];
		};
		paramset.set__ = { |self, id, value| // TODO: set__
			var param = self.lookup_param_(id);
			param.set__(value);
		};
		paramset.get_ = { |self, id|
			var param = self.lookup_param_(id);
			param.get_();
		};
		paramset.set_raw_ = { |self, id, value|
			var param = self.lookup_param_(id);
			param.set_raw_(value);
		};
		paramset.get_raw_ = { |self, id|
			var param = self.lookup_param_(id);
			param.get_raw_();
		};
		paramset.delta_ = { |self, id, delta|
			var param = self.lookup_param_(id);
			param.delta_(delta);
		};
		paramset.bang_ = { |self|
			self[\params].do { |param|
				param.bang_();
			};
		};
		paramset.write_ = { |self, filename, name|
			var file;
			filename = filename ? 1;
			if (filename.class == Integer) {
				filename = self.pr_resolve_number_pset_path_(filename);
			};
			postln("pset >> write: " ++ filename);
			File.use(filename.standardizePath, "w") { |file|
				if (name.notNil) {
					file.write("-- " ++ name ++ "\n");
				};
				self[\params].do { |param|
					if (param[\id].notNil and: (param[\type] != \trigger)) { // TODO: trigger?
						var value = param.get_();
						file.write("%: %\n".format(param[\id].asString.quote, value));
					};
				};
			};
		};
		paramset.read_ = { |self, filename|
			var file;
			var line;
			filename = filename ? 1;
			if (filename.class == Integer) {
				filename = self.pr_resolve_number_pset_path_(filename);
			};
			postln("pset >> read: " ++ filename);
			if (File.exists(filename.standardizePath)) {
				File.use(filename.standardizePath, "r") { |file|
					while { (line = file.getLine).notNil } {
						if (line.beginsWith("--")) {
							self[\name] = line[3..];
						} {
							var colon_pos;
							colon_pos = line.find($:);
							if (colon_pos.notNil) {
								var id, value;
								id = line[..colon_pos-1];
								value = line[colon_pos+2..];

								if (id.notNil and: value.notNil) {
									var unquoted_id = id[1..id.size-2];
									var param = self.lookup_param_(unquoted_id);

									if (param.notNil) {
										param.set__(value);
									} {
										"no param name % in paramset!".format(unquoted_id).warn; 
									};
									value = value[1..];
									param
								};
							};
						};
					};
				};
			} {
				postln("pset :: " ++ filename ++ " not read.");
			};
		};
		paramset.string_ = { |self, id|
/*
	TODO
			var param = self.lookup_param_(id);
			if (param[\formatter].notNil) {
				param[\formatter].value(param);
			} {
				var a = round(paramset.get_(param[\id]), 0.01);
				a.asString + param[\controlspec].units;
			};
*/
			var param = self.lookup_param_(id);
			param.string_();
		};
		paramset.list_ = { |self|
			postln("paramset [" ++ self.name ++ "]");
			self[\params].do { |param|
				postln(param[\id]);
			};
		};
		paramset.pr_resolve_number_pset_path_ = { |self, index|
			script_env.use {
				var data_folder = ~norns[\state][\data]; // TODO: script subfolder ?
				var shortname = ~norns[\state][\shortname];
				File.mkdir(data_folder);
				data_folder +/+ (shortname ++ "-" ++ index.asString ++ ".pset");
			};
		};
		paramset;
	};

	var module = IdentityDictionary[
		\init_paramset -> init_paramset
	];

	module;
}.value;

namespaces.ack_engine_loader = {
	var ack = include_engine_dependency.value(\ack);

	var init = ack[\init];
	var free = ack[\free];
	var loadSampleCommand = ack[\loadSampleCommand];
	var multiTrigCommand = ack[\multiTrigCommand];
	var trigCommand = ack[\trigCommand];
	var multiKillCommand = ack[\multiKillCommand];
	var killCommand = ack[\killCommand];
	var includeInMuteGroupCommand = ack[\includeInMuteGroupCommand];
	var sampleStartCommand = ack[\sampleStartCommand];
	var sampleEndCommand = ack[\sampleEndCommand];
	var loopPointCommand = ack[\loopPointCommand];
	var enableLoopCommand = ack[\enableLoopCommand];
	var disableLoopCommand = ack[\disableLoopCommand];
	var speedCommand = ack[\speedCommand];
	var volumeCommand = ack[\volumeCommand];
	var volumeEnvAttackCommand = ack[\volumeEnvAttackCommand];
	var volumeEnvReleaseCommand = ack[\volumeEnvReleaseCommand];
	var panCommand = ack[\panCommand];
	var filterCutoffCommand = ack[\filterCutoffCommand];
	var filterResCommand = ack[\filterResCommand];
	var filterModeCommand = ack[\filterModeCommand];
	var filterEnvAttackCommand = ack[\filterEnvAttackCommand];
	var filterEnvReleaseCommand = ack[\filterEnvReleaseCommand];
	var filterEnvModCommand = ack[\filterEnvModCommand];
	var sampleRateCommand = ack[\sampleRateCommand];
	var bitDepthCommand = ack[\bitDepthCommand];
	var distCommand = ack[\distCommand];
	var delaySendCommand = ack[\delaySendCommand];
	var reverbSendCommand = ack[\reverbSendCommand];
	var delayTimeCommand = ack[\delayTimeCommand];
	var delayFeedbackCommand = ack[\delayFeedbackCommand];
	var delayLevelCommand = ack[\delayLevelCommand];
	var reverbRoomCommand = ack[\reverbRoomCommand];
	var reverbDampCommand = ack[\reverbDampCommand];
	var reverbLevelCommand = ack[\reverbLevelCommand];
	var mainLevelCommand = ack[\mainLevelCommand];

	// server booted assumed
	var load_engine = {
		var ack_instance = init.value(
			(
				autostartServer: false,
				trace: false
			)
		);

		(
			ack_instance: ack_instance,
			commands: [
				\loadSample -> { |self, channelnum, path|
					loadSampleCommand.value(ack_instance, channelnum, path);
				},
				\multiTrig -> { |self ... channels|
					multiTrigCommand.valueArray([ack_instance]++channels);
				},
				\trig -> { |self ... args|
					trigCommand.valueArray([ack_instance]++args);
				},
				\multiKill -> { |self ... args|
					multiKillCommand.valueArray([ack_instance]++args);
				},
				\kill -> { |self ... args|
					killCommand.valueArray([ack_instance]++args);
				},
				\includeInMuteGroup -> { |self ... args|
					includeInMuteGroupCommand.valueArray([ack_instance]++args);
				},
				\sampleStart -> { |self ... args|
					sampleStartCommand.valueArray([ack_instance]++args);
				},
				\sampleEnd -> { |self ... args|
					sampleEndCommand.valueArray([ack_instance]++args);
				},
				\loopPoint -> { |self ... args|
					loopPointCommand.valueArray([ack_instance]++args);
				},
				\enableLoop -> { |self ... args|
					enableLoopCommand.valueArray([ack_instance]++args);
				},
				\disableLoop -> { |self ... args|
					disableLoopCommand.valueArray([ack_instance]++args);
				},
				\speed -> { |self ... args|
					speedCommand.valueArray([ack_instance]++args);
				},
				\volume -> { |self ... args|
					volumeCommand.valueArray([ack_instance]++args);
				},
				\volumeEnvAttack -> { |self ... args|
					volumeEnvAttackCommand.valueArray([ack_instance]++args);
				},
				\volumeEnvRelease -> { |self ... args|
					volumeEnvReleaseCommand.valueArray([ack_instance]++args);
				},
				\pan -> { |self ... args|
					panCommand.valueArray([ack_instance]++args);
				},
				\filterCutoff -> { |self ... args|
					filterCutoffCommand.valueArray([ack_instance]++args);
				},
				\filterRes -> { |self ... args|
					filterResCommand.valueArray([ack_instance]++args);
				},
				\filterMode -> { |self ... args|
					filterModeCommand.valueArray([ack_instance]++args);
				},
				\filterEnvAttack -> { |self ... args|
					filterEnvAttackCommand.valueArray([ack_instance]++args);
				},
				\filterEnvRelease -> { |self ... args|
					filterEnvReleaseCommand.valueArray([ack_instance]++args);
				},
				\filterEnvMod -> { |self ... args|
					filterEnvModCommand.valueArray([ack_instance]++args);
				},
				\sampleRate -> { |self ... args|
					sampleRateCommand.valueArray([ack_instance]++args);
				},
				\bitDepth -> { |self ... args|
					bitDepthCommand.valueArray([ack_instance]++args);
				},
				\dist -> { |self ... args|
					distCommand.valueArray([ack_instance]++args);
				},
				\delaySend -> { |self ... args|
					delaySendCommand.valueArray([ack_instance]++args);
				},
				\reverbSend -> { |self ... args|
					reverbSendCommand.valueArray([ack_instance]++args);
				},
				\delayTime -> { |self ... args|
					delayTimeCommand.valueArray([ack_instance]++args);
				},
				\delayFeedback -> { |self ... args|
					delayFeedbackCommand.valueArray([ack_instance]++args);
				},
				\delayLevel -> { |self ... args|
					delayLevelCommand.valueArray([ack_instance]++args);
				},
				\reverbRoom -> { |self ... args|
					reverbRoomCommand.valueArray([ack_instance]++args);
				},
				\reverbDamp -> { |self ... args|
					reverbDampCommand.valueArray([ack_instance]++args);
				},
				\reverbLevel -> { |self ... args|
					reverbLevelCommand.valueArray([ack_instance]++args);
				},
				\mainLevel -> { |self ... args|
					mainLevelCommand.valueArray([ack_instance]++args);
				}
			],
			polls: []
		)
	};

	var free_engine = { |instance| // TODO: not triggered yet, right?
		free.value(instance[\ack_instance]);
	};

	var module = IdentityDictionary[
		\load_engine -> load_engine,
		\free_engine -> free_engine
	];

	module
};

namespaces.r_engine_loader = {
	var rrrr = include_engine_dependency.value(\r);

	var init = rrrr[\init];
	var free = rrrr[\free];
	var newCommand = rrrr[\newCommand];
	var connectCommand = rrrr[\connectCommand];
	var disconnectCommand = rrrr[\disconnectCommand];
	var deleteCommand = rrrr[\deleteCommand];
	var setCommand = rrrr[\setCommand];
	var bulksetCommand = rrrr[\bulksetCommand];
	var newmacroCommand = rrrr[\newmacroCommand];
	var deletemacroCommand = rrrr[\deletemacroCommand];
	var macrosetCommand = rrrr[\macrosetCommand];
	var readsampleCommand = rrrr[\readsampleCommand];
	var tapoutputCommand = rrrr[\tapoutputCommand];
	var tapclearCommand = rrrr[\tapclearCommand];
	var getTapBus = rrrr[\getTapBus];
	var getVisualBus = rrrr[\getVisualBus];

	// server booted assumed
	var load_engine = {
		var numPolls = 10;
		var default_poll_rate = 10; // poll updates per second

		var postPollIndexNotWithinBoundsError = { |pollIndex|
			"poll index not within bounds: pollIndex % referred, only % polls available".format(pollIndex, numPolls).error;
		};

		var ifPollIndexWithinBoundsDo = { |oneBasedIndex, func|
			if ((1 <= oneBasedIndex) and: (oneBasedIndex <= numPolls)) {
				func.value;
			} {
				postPollIndexNotWithinBoundsError.value(oneBasedIndex);
			};
		};

		var polloutputCommand = { |instance, oneBasedIndex, outputRef|
			ifPollIndexWithinBoundsDo.value(oneBasedIndex) {
				var zeroBasedIndex = oneBasedIndex - 1; // lua based indexing is used in engine interface
				var pollConfig = pollConfigs[zeroBasedIndex];
				if (pollConfig[\type].notNil) {
					pollclearCommand.value(oneBasedIndex);
				};
				tapoutputCommand.value(instance, zeroBasedIndex, outputRef);
				pollConfig[\type] = \out;
				pollConfig[\outputRef] = outputRef;
				pollConfig[\bus] = getTapBus.value(instance, zeroBasedIndex);
			};
		};

		var pollvisualCommand = { |instance, oneBasedIndex, visual|
			ifPollIndexWithinBoundsDo.value(oneBasedIndex) {
				var zeroBasedIndex = oneBasedIndex - 1; // lua based indexing is used in engine interface
				var pollConfig = pollConfigs[zeroBasedIndex];
				if (pollConfig[\type].notNil) {
					pollclearCommand.value(oneBasedIndex);
				};
				pollConfig[\type] = \visual;
				pollConfig[\visual] = visual;
				pollConfig[\bus] = getVisualBus.value(instance, visual);
			};
		};

		var pollclearCommand = { |instance, oneBasedIndex|
			ifPollIndexWithinBoundsDo.value(oneBasedIndex) {
				var zeroBasedIndex = oneBasedIndex - 1; // lua based indexing is used in engine interface
				var pollConfig = pollConfigs[zeroBasedIndex];
				if (pollConfig[\type] == \out) {
					tapclearCommand.value(instance, zeroBasedIndex);
				};
				pollConfig[\type] = nil;
				pollConfig[\outputRef] = nil;
				pollConfig[\visual] = nil;
				pollConfig[\bus] = nil;
			};
		};

		var pollConfigs = () ! numPolls;

		var r_instance = init.value(
			(
				autostartServer: false,
				trace: false
			)
		);

		(
			r_instance: r_instance,
			commands: [
				\new -> { |self, name, kind|
					newCommand.value(r_instance, name, kind);
				},
				\connect -> { |self, moduleOutputRef, moduleInputRef|
					connectCommand.value(r_instance, moduleOutputRef, moduleInputRef);
				},
				\disconnect -> { |self, moduleOutputRef, moduleInputRef|
					disconnectCommand.value(r_instance, moduleOutputRef, moduleInputRef);
				},
				\delete -> { |self, moduleRef|
					deleteCommand.value(r_instance, moduleRef);
				},
				\set -> { |self, moduleParameterRef, value| // TODO: compare with paramset - this turns into "set_" whereas paramset has "set__"
					setCommand.value(r_instance, moduleParameterRef, value);
				},
				\bulkset -> { |self, bundle|
					bulksetCommand.value(r_instance, bundle);
				},
				\newmacro -> { |self, name, bundle|
					newmacroCommand.value(r_instance, name, bundle);
				},
				\deletemacro -> { |self, name|
					deletemacroCommand.value(r_instance, name);
				},
				\macroset -> { |self, name, value|
					macrosetCommand.value(r_instance, name, value);
				},
				\polloutput -> { |self, oneBasedIndex, outputRef|
					polloutputCommand.value(r_instance, oneBasedIndex, outputRef);
				},
				\pollvisual -> { |self, oneBasedIndex, visual|
					pollvisualCommand.value(r_instance, oneBasedIndex, visual);
				},
				\pollclear -> { |self, oneBasedIndex|
					pollclearCommand.value(r_instance, oneBasedIndex);
				}
			],
			polls: numPolls.collect { |pollIndex|
				("poll" ++ (pollIndex+1)).asSymbol -> (
					func: {
						var pollConfig = pollConfigs[pollIndex];
						var bus, value;

						// TODO: if pollConfig type not out nor visual, just skip?

						bus = pollConfig[\bus];
						if (bus.notNil) {
							value = bus.getSynchronous; // note: getSynchronous does not work with remote servers
						};

						value;
					},
					time: (1/default_poll_rate)
				)
			}
		)
	};

	var free_engine = { |instance| // TODO: not triggered yet, right?
		free.value(instance[\r_instance]);
	};

	var module = IdentityDictionary[
		\load_engine -> load_engine,
		\free_engine -> free_engine
	];

	module
};

namespaces.param_ui_manager = {

	var screen_width = 128;
	var screen_height = 64;
	var screen_x_spec = ControlSpec(1, screen_width, 'linear', 1, 0, "");
	var screen_y_spec = ControlSpec(1, screen_height, 'linear', 1, 0, "");
	var screen_l_spec = ControlSpec(0, 15, 'linear', 1, 0, "");

	var hi_level = screen_l_spec.maxval;
	var lo_level = round(screen_l_spec.maxval/4);
	var mid_level = round((hi_level+lo_level)/2); // TODO

	var redraw_row_label = { |label, y_pos, level|
		~screen.level_(level);
		~screen.move_(1, y_pos);
		~screen.text_(label.asString);
	};

	var redraw_row_value = { |value, y_pos, level|
		~screen.level_(level);
		~screen.move_(128, y_pos);
		~screen.text_right_(value.asString);
	};

	var redraw_param = { |param, y_pos, level|
		case
		{ param[\type] == 'separator' } {
			redraw_row_label.value(Array.fill(35) { "_" }.join, y_pos, level);
		}
		{ ['file', 'control', 'option', 'number'].includes(param[\type]) } {
			redraw_row_label.value(param[\name], y_pos, level);
			redraw_row_value.value(param.string_(), y_pos, level);
		};
	};

	var init_param_ui_manager = { |script_env|
		var row_height = 10;
		var params_per_page = 6;

		var param_ui = (
			cursor: 0
		);

		param_ui.redraw_ = { |self|
			var cursor = self[\cursor];

			~screen.clear_();
			~screen.font_size_(8);

			((-2) max: (((cursor-2) min: (~params[\count]-params_per_page)))..((cursor+3) min: (~params[\count]))).do { |param_index, index|
				case
				{param_index == -2} {
					redraw_row_label.value("PARAMETERS", 1 + row_height, lo_level);
				}
				{param_index == -1} {
				}
				{true} {
					if (param_index < ~params[\count]) {
						var param = ~params[\params][param_index];
						var level;
						if ((param_ui[\active] == 'param_ui_row') and: ((index+1) == param_ui[\param_ui_row])) {
							level = hi_level;
						} {
							if ((param_ui[\focus] == 'param_ui_row') and: ((index+1) == param_ui[\param_ui_row])) {
								level = mid_level;
							} {
								if (param_index == cursor) {
									level = hi_level;
								} {
									level = lo_level;
								};
							};
						};
						redraw_param.value(param, 1 + ((index+1) * row_height), level);
					};
				}
			};

			~screen.update_();
		};

		param_ui.key_ = { |self, n, z|
			~redraw.value();
		};

		param_ui.enc_ = { |self, n, delta|
			case
			{n == 2} {
				param_ui.cursor_delta_(delta);
			}
			{n == 3} {
				param_ui.selected_param_delta_(delta);
			}
			;
			~redraw.value();
		};

		param_ui.kbdkey_ = { |self, keycode, z|
			case
			{(keycode == 40) and: (z == 1)} {
				param_ui.cursor_delta_(1);
			}
			{(keycode == 38) and: (z == 1)} {
				param_ui.cursor_delta_(-1);
			}
			{(keycode == 37) and: (z == 1)} {
				param_ui.selected_param_delta_(-1);
			}
			{(keycode == 39) and: (z == 1)} {
				param_ui.selected_param_delta_(1);
			}
			;
			~redraw.value();
		};

		param_ui.mouse_ = { |self, what, args|
			case
			{ what == "leave" } {
				self.mouse_leave_();
			}
			{ what == "over" } {
				var x_pos = args[0], y_pos = args[1];
				self.mouse_over_(x_pos, y_pos);
			}
			{ what == "down" } {
				var x_pos = args[0], y_pos = args[1];
				self.mouse_down_(x_pos, y_pos);
			}
			{ what == "move" } {
				var x_pos = args[0], y_pos = args[1];
				self.mouse_move_(x_pos, y_pos);
			}
			{ what == "up" } {
				var x_pos = args[0], y_pos = args[1];
				self.mouse_up_(x_pos, y_pos);
			}
			{ what == "wheel" } {
				var x_delta = args[0], y_delta = args[1];
				self.mouse_wheel_(x_delta, y_delta);
			};
			~redraw.value();
		};

		param_ui.cursor_delta_ =
		{ |self, delta|
			self[\cursor] = (self[\cursor] + delta) min: (~params[\count]-1) max: 0;
		};

		param_ui.selected_param_delta_ =
		{ |self, delta|
			var param = ~params[\params][self[\cursor]];
			param.delta_(delta);
		};

		param_ui.within_param_value_bounds_ =
		{ |self, pos|
			self.get_row_at_(pos).notNil;
		};

		param_ui.get_row_at_ =
		{ |self, pos|
			round(pos.y / row_height);
		};

		param_ui.update_focus_ =
		{ |self, pos|
			case
			{ self.within_param_value_bounds_(pos) } {
				self.focus = 'param_ui_row';
				self.param_ui_row = self.get_row_at_(pos);
			}
			{ true } {
				self.focus = nil;
				self.param_ui_row = nil;
			};
		};

		param_ui.mouse_over_ =
		{ |self, x_pos, y_pos|
			self.mouse_over_pos = x_pos@y_pos;
			self.update_focus_(self.mouse_over_pos); // TODO: only if mouse is not pressed(?)
		};

		param_ui.mouse_down_ =
		{ |self, x_pos, y_pos|
			self.mouse_down_pos = x_pos@y_pos;

			case
			{ self.focus == 'param_ui_row' } {
			}
			;

			self.active = self.focus;
		};

		param_ui.mouse_move_ =
		{ |self, x_pos, y_pos|
			var mouse_move_delta;

			var cursor = self[\cursor];
			var prev_mouse_move_pos = self.mouse_move_pos;

			self.mouse_move_pos = x_pos@y_pos;
			mouse_move_delta = (prev_mouse_move_pos ? self.mouse_down_pos) - (x_pos@y_pos);

			case
			{ self.active == 'param_ui_row' } {
				if (mouse_move_delta.y != 0) {
					{ |cursor, param_ui_row, delta|
						var param_index = ((-2) max: (((cursor-2) min: (~params[\count]-params_per_page)))..((cursor+3) min: (~params[\count])))[param_ui_row];
						var param_in_focus = ~params[\params][param_index];

						var fine = false; // TODO
						var divisor;

						if (param_in_focus.notNil) {
							if (fine) {
								divisor = 5;
							} {
								divisor = 1;
							};
							param_in_focus.delta_(delta/divisor);
						};
					}.value(self[\cursor], self[\param_ui_row]-1, mouse_move_delta.y);
				};
			}
			;
		};

		param_ui.mouse_wheel_ =
		{ |self, x_delta, y_delta|
			if (y_delta != 0) {
				case
				{self.focus == 'param_ui_row'} {
					{ |cursor, param_ui_row, delta|
						var param_index = ((-2) max: (((cursor-2) min: (~params[\count]-params_per_page)))..((cursor+3) min: (~params[\count])))[param_ui_row];
						var param_in_focus = ~params[\params][param_index];

						var fine = false; // TODO
						var divisor;

						if (param_in_focus.notNil) {
							if (fine) {
								divisor = 5;
							} {
								divisor = 1;
							};
							param_in_focus.delta_(delta/divisor);
						};
					}.value(self[\cursor], self[\param_ui_row]-1, y_delta);
				};
			};
		};

		param_ui.mouse_up_ =
		{ |self, x_pos, y_pos|
			self.mouse_move_pos = nil;
			self.active = nil;
			self.update_focus_(x_pos@y_pos);
		};

		param_ui.mouse_leave_ =
		{ |self|
			self.focus = nil;
		};

		param_ui;
	};

	// TODO: implement free_param_ui_manager

	var module = IdentityDictionary[
		\init_param_ui_manager -> init_param_ui_manager
	];

	module;
}.value;

namespaces.device_to_enc_key_mapper = {

	var init_device_to_enc_key_mapper = { |script_env|
		var mapper = ();
		mapper.handle_midi_ = { |self, message|
			if ((message[\chan] == 0) and: (message[\type] == \cc)) {
				var val = message[\val];
				var num = message[\num];
				case
				{ (num == 1) and: ([1, 127].includes(val)) } {
					script_env.use {
						~enc.value(2, if (val == 127, -1, 1));
					}
				}
				{ (num == 2) and: ([1, 127].includes(val)) } {
					script_env.use {
						~enc.value(3, if (val == 127, -1, 1));
					}
				}
				{ (num == 4) and: ([1, 127].includes(val)) } {
					script_env.use {
						~enc.value(1, if (val == 127, -1, 1));
					}
				}
				{ (num == 50) and: ([0, 127].includes(val)) } {
					script_env.use {
						~key.value(2, if (val == 127, 1, 0));
					}
				}
				{ (num == 51) and: ([0, 127].includes(val)) } {
					script_env.use {
						~key.value(3, if (val == 127, 1, 0));
					}
				}
				{ (num == 48) and: ([0, 127].includes(val)) } {
					if (val == 127) {
						script_env.use {
							if (~norns[\showing_param_ui].asBoolean) {
								~switch_to_script.value();
								~norns[\showing_param_ui] = false;
							} {
								~switch_to_params_ui.value();
								~norns[\showing_param_ui] = true;
							};
						};
					};
				}
				;
			} {
				nil
			};
		};
	};

	// TODO: implement free_device_to_enc_key_mapper

	var module = IdentityDictionary[
		\init_device_to_enc_key_mapper -> init_device_to_enc_key_mapper
	];

	module;
}.value;

if (~include_nel_libraries.asBoolean) { // TODO: ugly hack, get around using globals here
	namespaces;
} {
	{
		var arc_device_manager = namespaces[\arc_device_manager];
		var init_arc_device_manager = arc_device_manager[\init_arc_device_manager];
		var free_arc_device_manager = arc_device_manager[\free_arc_device_manager];

		var midi_device_manager = namespaces[\midi_device_manager];
		var init_midi_device_manager = midi_device_manager[\init_midi_device_manager];
		var free_midi_device_manager = midi_device_manager[\free_midi_device_manager];

		var grid_device_manager = namespaces[\grid_device_manager];
		var init_grid_device_manager = grid_device_manager[\init_grid_device_manager];
		var free_grid_device_manager = grid_device_manager[\free_grid_device_manager];

		var poll_manager = namespaces[\poll_manager];
		var init_poll_manager = poll_manager[\init_poll_manager];
		var free_poll_manager = poll_manager[\free_poll_manager];

		var metro_manager = namespaces[\metro_manager];
		var init_metro_manager = metro_manager[\init_metro_manager];

		var screen = namespaces[\screen];
		var init_screen = screen[\init_screen];

		var paramset = namespaces[\paramset];
		var init_paramset = paramset[\init_paramset];

		var param_ui_manager = namespaces[\param_ui_manager];
		var init_param_ui_manager = param_ui_manager[\init_param_ui_manager];
		var free_param_ui_manager = param_ui_manager[\free_param_ui_manager]; // TODO

		var device_to_enc_key_mapper = namespaces[\device_to_enc_key_mapper];
		var init_device_to_enc_key_mapper = device_to_enc_key_mapper[\init_device_to_enc_key_mapper];
		var free_device_to_enc_key_mapper = device_to_enc_key_mapper[\free_device_to_enc_key_mapper]; // TODO

		var scale = 6;
		var screen_width = 128 * scale;
		var screen_height = 64 * scale;

		var margin_x = 6 * scale;
		var margin_y = 3 * scale;

		var window_width = screen_width + (margin_x*2);
		var window_height = screen_height + (margin_y*2);

		var setup_engine_globals = { |commands, polls|
			var engine;
			engine = ();
			commands.do { |command|
				engine[(command.key.asString++"_").asSymbol] = command.value;
			};
			[engine, init_poll_manager.value(polls)];
		};

		var start_script = { |script_name, script_func|
			var script_env;

			var window = Window.new(
				script_name,
				Rect(
					Window.screenBounds.width - window_width - 25,
					Window.screenBounds.height - window_height - 50,
					window_width,
					window_height
				))
				.background_(Color.black);

			var screen = init_screen.value(window, margin_x, margin_y, scale);
			var screen_api = screen[\singleton];
			var screen_view = screen[\view];

			var spawn_script_func = {
				var script_instance = ();

				var setup_window_mouse_and_key_hooks = {
					var enc_area_pressed = false ! 3;
					var enc_area_prev_pos;
					var key_state = false ! 3;

					window.view
						.acceptsMouseOver_(true)
						.keyModifiersChangedAction_({ |view, modifiers|
							var shift_pressed;
							var ctrl_pressed;
							var alt_pressed;

							shift_pressed = modifiers & 131072 == 131072;

							ctrl_pressed = modifiers & 262144 == 262144;

							alt_pressed = modifiers & 524288 == 524288;

							case
								{ key_state[0].not and: shift_pressed }
								{
									script_env.use {
										if (~norns[\showing_param_ui].asBoolean) {
											switch_to_script.value();
											~norns[\showing_param_ui] = false;
										} {
											~switch_to_params_ui.value();
											~norns[\showing_param_ui] = true;
										};
									};
/*
	TODO
									key_state[0] = true;
									script_env.use {
										~key.value(1, 1);
									};
*/
								}
								{ key_state[0] and: shift_pressed.not }
								{
/*
	TODO
									key_state[0] = false;
									script_env.use {
										~key.value(1, 0);
									};
*/
								}
							;

							case
								{ key_state[1].not and: ctrl_pressed }
								{
									key_state[1] = true;
									script_env.use {
										~key.value(2, 1);
									};
								}
								{ key_state[1] and: ctrl_pressed.not }
								{
									key_state[1] = false;
									script_env.use {
										~key.value(2, 0);
									};
								}
							;

							case
								{ key_state[2].not and: alt_pressed }
								{
									key_state[2] = true;
									script_env.use {
										~key.value(3, 1);
									};
								}
								{ key_state[2] and: alt_pressed.not }
								{
									key_state[2] = false;
									script_env.use {
										~key.value(3, 0);
									};
								}
							;
						})
						.keyDownAction_({ |view, char, modifiers, unicode, keycode, key|
							var ctrl_pressed = modifiers & 262144 == 262144;
							if (ctrl_pressed and: (keycode == 32) or: (keycode == 27)) {
								CmdPeriod.run;
							} {
								// TODO [char, modifiers, unicode, keycode, key].debug(\down);
								script_env.use {
									~kbdkey.value(keycode, 1);
								};
							};
						})
						.keyUpAction_({ |view, char, modifiers, unicode, keycode, key|
							script_env.use {
								~kbdkey.value(keycode, 0);
							};
						})
						;
				};

				var switch_to_script = {
					var saved_script_hooks = ~norns[\saved_script_hooks];
					~redraw = saved_script_hooks[\redraw];
					~enc = saved_script_hooks[\enc];
					~key = saved_script_hooks[\key];
					~mouse = saved_script_hooks[\mouse];
					~kbdkey = saved_script_hooks[\kbdkey];
					~norns[\saved_script_hooks] = nil;
					~redraw.value();
				};

				var switch_to_params_ui = {
					~norns[\saved_script_hooks] = (
						redraw: ~redraw,
						enc: ~enc,
						key: ~key,
						mouse: ~mouse,
						kbdkey: ~kbdkey,
					);
					~redraw = {
						~param_ui.redraw_();
					};
					~enc = { |index, delta|
						~param_ui.enc_(index, delta);
					};
					~key = { |index, state|
						~param_ui.key_(index, state);
					};
					~mouse = { |what ... args|
						~param_ui.mouse_(what, args);
					};
					~kbdkey = { |keycode, state|
						~param_ui.kbdkey_(keycode, state);
					};
					~redraw.value();
				};

				var mouse_pressed_pos;
				var mouse_over_pos;
				var mouse_drag_pos;
				var mouse_move_pos;

				var scale_mouse_pos = { |x, y|
					(round(x/scale)+1 /* TODO max: 1*/)@(round(y/scale)+1 /* TODO max: 1*/)
				};

				var mouse_enter_action = { |view|
					script_env.use {
						~mouse.value("enter");
					};
				};

				var mouse_drag_action = { |view, x, y|
					var scaled_pos = scale_mouse_pos.value(x, y);
					if (mouse_drag_pos != scaled_pos) {
						mouse_drag_pos = scaled_pos;
						script_env.use {
							~mouse.value("drag", scaled_pos.x, scaled_pos.y, View.currentDrag);
						};
					};
				};

				var mouse_over_action = { |view, x, y|
					var scaled_pos = scale_mouse_pos.value(x, y);
					if (mouse_over_pos != scaled_pos) {
						mouse_over_pos = scaled_pos;
						script_env.use {
							~mouse.value("over", scaled_pos.x, scaled_pos.y);
						};
					};
				};

				var mouse_down_action = { |view, x, y, modifiers, buttonNumber|
					var scaled_pos = scale_mouse_pos.value(x, y);
					mouse_pressed_pos = scaled_pos;
					script_env.use {
						~mouse.value("down", scaled_pos.x, scaled_pos.y, buttonNumber+1);
					};
				};

				var mouse_wheel_action = { |view, x, y, modifier, xDelta, yDelta|
					if ((xDelta != 0) or: (yDelta != 0)) { // in 3.10 qt gui xDelta, yDelta is not always reported correctly: https://github.com/supercollider/supercollider/issues/4422
						script_env.use {
							~mouse.value("wheel", xDelta, yDelta);
						};
					};
				};

				var mouse_move_action = { |view, x, y|
					var scaled_pos = scale_mouse_pos.value(x, y);
					if (mouse_move_pos != scaled_pos) {
						mouse_move_pos = scaled_pos;
						script_env.use {
							~mouse.value("move", scaled_pos.x, scaled_pos.y);
						};
					};
				};

				var mouse_up_action = { |view, x, y|
					var scaled_pos = scale_mouse_pos.value(x, y);
					script_env.use {
						~mouse.value("up", scaled_pos.x, scaled_pos.y);
					};
				};

				var mouse_leave_action = { |view|
					script_env.use {
						~mouse.value("leave");
					};
				};

				var teardown_function = {
					pr_stop_script.value(script_instance);
				};

				var load_engine_library_lazily = { |engine_name|
					var engine_namespace_sym = (engine_name.asString ++ "_engine").asSymbol;
					var engine_namespace_string = engine_namespace_sym.asString;
					if (namespaces[engine_namespace_sym].notNil) {
						"in load_engine_library_lazily: using cached % engine library".format(engine_name.asString).inform;
						namespaces[engine_namespace_sym]
					} {
						"in load_engine_library_lazily: loading % engine library anew".format(engine_name.asString).inform;
						namespaces[engine_namespace_sym] = namespaces[(engine_namespace_string ++ "_loader").asSymbol].value;
						namespaces[engine_namespace_sym];
					};
				};

				script_env = Environment.make {
					~norns = (
						state: (
							data: Platform.userConfigDir +/+ "norns_engine_tester" +/+ "data" ++ Platform.pathSeparator,
							name: script_name.asString,
							shortname: script_name.asString
						)
					);

					~screen = screen_api;
					~metro = init_metro_manager.value;
					~params = init_paramset.value(currentEnvironment);
					~midi = init_midi_device_manager.value(currentEnvironment);
					~arc = init_arc_device_manager.value(currentEnvironment);
					~grid = init_grid_device_manager.value(currentEnvironment);
					~param_ui = init_param_ui_manager.value(currentEnvironment);
					~device_to_enc_key_mapper = init_device_to_enc_key_mapper.value(currentEnvironment);

					~switch_to_script = switch_to_script;
					~switch_to_params_ui = switch_to_params_ui;

					defer {
						setup_window_mouse_and_key_hooks.value;
					};

					~engine = ();

					script_func.value; // TODO: error handling, cleanup

					{
						var completeFunc = {
							~init.value;
							window.front;
							~redraw.value;
						};
	
						case
						{~engine[\name] == 'R' } {
							var r_engine = load_engine_library_lazily.value(\r);
							var load_engine = r_engine[\load_engine];
							var free_engine = r_engine[\free_engine];

							s.waitForBoot {
								var r_engine_instance = load_engine.value;
								var engine, polls;
								# engine, poll_manager = setup_engine_globals.value(r_engine_instance[\commands], r_engine_instance[\polls]);
								~engine = engine;
								~poll = poll_manager;
								script_instance[\engine_free_func] = {
									free_engine.value(r_engine_instance);
								};
								"R engine loaded".inform;
								completeFunc.value;
							};
						}
						{~engine[\name] == 'Ack' } {
							var ack_engine = load_engine_library_lazily.value(\ack);
							var load_engine = ack_engine[\load_engine];
							var free_engine = ack_engine[\free_engine];

							s.waitForBoot {
								var ack_engine_instance = load_engine.value;
								var engine, polls;
								# engine, poll_manager = setup_engine_globals.value(ack_engine_instance[\commands], ack_engine_instance[\polls]);
								~engine = engine;
								~poll = poll_manager;
								script_instance[\engine_free_func] = {
									free_engine.value(ack_engine_instance);
								};
								"Ack engine loaded".inform;
								completeFunc.value;
							};
						}
						{ true } {
							"not supported engine".error;
							completeFunc.value;
						};
					}.value;
				};

				script_instance[\environment] = script_env;

				~scripts = ~scripts.add(script_env); // TODO: this goes to the currentEnvironment - do this in topEnvironment instead?
				// TODO 2: call this script_envs since they're environments?

				CmdPeriod.doOnce(teardown_function);

				{ // deferred since Qt requires properties to be set in AppClock
					screen_view
						.mouseEnterAction_(mouse_enter_action)
						.mouseOverAction_(mouse_over_action)
						.mouseOverAction_(mouse_over_action)
						.receiveDragHandler_(mouse_drag_action)
						.mouseDownAction_(mouse_down_action)
						.mouseWheelAction_(mouse_wheel_action)
						.mouseMoveAction_(mouse_move_action)
						.mouseUpAction_(mouse_up_action)
						.mouseLeaveAction_(mouse_leave_action)
						;

					window.view
						.onResize_({ |windowView|
							var bounds = windowView.bounds;
							screen_view.moveTo(
								(bounds.width/2)-(screen_view.bounds.width/2),
								(bounds.height/2)-(screen_view.bounds.height/2)
							);
						})
						.onClose_(teardown_function);
				}.defer;

				script_instance[\window] = window;
				script_instance[\teardown_function] = teardown_function;
			};

			if (class_exists.value('SerialOSCClient')) {
				var serialOSCClientClass = load_class_dynamically.value("SerialOSCClient");
				serialOSCClientClass.init(spawn_script_func);
			} {
				spawn_script_func.value;
			};
		};

		var free_script = { |script_env|
			free_poll_manager.value(script_env[\poll]);
			free_midi_device_manager.value(script_env[\midi]);
			free_arc_device_manager.value(script_env[\arc]);
			free_grid_device_manager.value(script_env[\grid]);
		};

		var select_script_environment = { |script_index|
			var scripts = topEnvironment[\scripts];
			if (scripts.notNil) {
				var currentScriptEnvIndex = scripts.detectIndex { |script_environment| script_environment == currentEnvironment };
				var script = scripts[script_index];

				if (script.notNil) {
					if (currentScriptEnvIndex.notNil) {
						"script #%'s environment popped".format(currentScriptEnvIndex).inform; // TODO: print script name
						Environment.pop;
					};
					script.push;
					"script #%'s environment pushed".format(script_index).inform; // TODO: print script name
				} {
					Error("no script with index % in scripts array!".format(script_index)).throw;
				};
			} {
				Error("no scripts array in topEnvironment!").throw;
			};
		};

		var stop_script = { |script_instance|
			// TODO: remove CmdPeriod function hooked to pr_stop_script
		};

		var pr_stop_script = { |script_instance|
			var script_env = script_instance[\environment];
			var engine_free_func = script_instance[\engine_free_func];
			var teardown_function = script_instance[\teardown_function];
			var window = script_instance[\window];

			"script cleanup...".inform;
			script_env.use {
				~cleanup.value;
				~metro.free_all_();
			};
			"freeing script device managers...".inform;
			free_script.value(script_env);
			"freeing engine...".inform;
			fork { // TODO: what was this about? polls still trying to getSynchronous ?
				0.2.wait;
				engine_free_func.value;
				~scripts.remove(script_env); // TODO: this removes from the currentEnvironment - do this in topEnvironment instead?
			};
			"removing CmdPeriod teardown function...".inform;
			CmdPeriod.remove(teardown_function);
			if (window.isClosed.not) {
				"closing script screen window...".inform;
				window.view.onClose = nil;
				window.close;
			};
			"... script successfully freed.".inform;
			// TODO: stop running routines
		};

		var module = IdentityDictionary[
			\start_script -> start_script,
			\select_script_environment -> select_script_environment,
			\stop_script -> stop_script
		];

		module;
	}.value;
};
)
