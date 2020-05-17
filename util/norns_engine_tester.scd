(
var namespaces = ();

namespaces.arc_device_manager = {
	// utility library to use a SerialOSCEnc to mock a norns enc, implementing a subset of functions.

	var init_arc_device_manager = { |script_env|
		var arc_device_manager = ();

		arc_device_manager['__enc_delta_funcs__'] = [];

		arc_device_manager.connect_ = { |self, n|
			var arc_device;

			n = n ? 1; 

			if (n != 1) {
				Error("multiple arcs are not supported").throw
			};

			arc_device = ();
			arc_device.led_ = { |self, ring, x, val|
				SerialOSCEnc.ringSet(ring-1, x-1, val);
			};
			arc_device.all_ = { |self, ring, val|
				SerialOSCEnc.ringAll(ring-1, val);
			};

			arc_device_manager['__enc_delta_funcs__'] = arc_device_manager['__enc_delta_funcs__'].add(
				EncDeltaFunc(
					{ |ring, n, delta|
						script_env.use {
							arc_device[\delta].value(ring+1, n+1, delta);
						};
					}
				)
			);

			arc_device;
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
		midi_device_manager.connect_ = { |self, n|
			var midi_device;

			MIDIIn.connectAll;

			n = n ? 1; 

			if (n != 1) {
				Error("multiple midi devices are not supported").throw
			};

			midi_device = ();

/*
			TODO: midi_device out
			midi_device.send_ = { |self, data|
				MIDIOut....
			};
*/

			midi_device_manager['__midi_funcs__'] = midi_device_manager['__midi_funcs__'].add(
				MIDIFunc.cc(
					{ |val, num, chan|
						script_env.use {
							midi_device[\event].value(
								(
									type: 'cc',
									val: val,
									num: num,
									chan: chan
								)
							);
						};
					}
				)
			);

			midi_device_manager['__midi_funcs__'] = midi_device_manager['__midi_funcs__'].add(
				MIDIFunc.noteOn(
					{ |vel, note, chan|
						script_env.use {
							midi_device[\event].value(
								(
									type: 'note_on',
									vel: vel,
									note: note,
									chan: chan
								)
							);
						};
					}
				)
			);

			midi_device_manager['__midi_funcs__'] = midi_device_manager['__midi_funcs__'].add(
				MIDIFunc.noteOff(
					{ |vel, note, chan|
						script_env.use {
							midi_device[\event].value(
								(
									type: 'note_off',
									vel: vel,
									note: note,
									chan: chan
								)
							);
						};
					}
				)
			);

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
			var grid_device;

			n = n ? 1; 

			if (n != 1) {
				Error("multiple grids are not supported").throw
			};

			grid_device = ();
			grid_device.led_ = { |self, x, y, val|
				SerialOSCGrid.ledLevelSet(x-1, y-1, val);
			};
			grid_device.all_ = { |self, val|
				SerialOSCGrid.ledLevelAll(val);
			};
			grid_device.cols_ = { |self|
				SerialOSCGrid.numCols;
			};
			grid_device.rows_ = { |self|
				SerialOSCGrid.numRows;
			};

			grid_device_manager['__grid_key_funcs__'] = grid_device_manager['__grid_key_funcs__'].add(
				GridKeyFunc(
					{ |x, y, state|
						script_env.use {
							grid_device[\key].value(x+1, y+1, state);
						};
					}
				)
			);

			grid_device;
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

namespaces.metro = {
	var init_metro = {
		var metros = [];

		var metro = ();

		metro.init_ = { |self, config|
			var event = config !? _.event;
			var time = (config !? _.time) ? 1;
			var count = (config !? _.count) ? inf;
			var new_metro;

			new_metro = ();
			new_metro[\event] = event;
			new_metro[\time] = time;
			new_metro[\count] = count;
			new_metro[\id] = metros.size;
			new_metro[\is_running] = false;
			new_metro.start_ = { |self, time, count|
				if (time.notNil) {
					self[\time] = time;
				};
				if (count.notNil) {
					self[\count] = count;
				};
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
				metros.remove(self);
			};

			metros = metros.add(new_metro);

			new_metro;
		};

		metro.free_all_ = { |self|
			metros.copy.do { |metro|
				metro.free_();
			};
		};

		metro;
	};

	var free_metro = {
		// TODO: possibly replace free_all with this
	};

	var module = IdentityDictionary[
		\init_metro -> init_metro
	];

	module;
}.value;

namespaces.screen = {
	// utility library to mock a UserView as a norns screen, drawable with a limited subset of norns screen functions. uses 1 based coordinates. uses global ~screen global for storage of relevant objects (not functions). relies on global ~redraw function wherein screen_* commands are performed.

	var screen_width = 128;
	var screen_height = 64;
	var default_font_size = 8;

	var default_background_color = Color.black;
	var default_foreground_color = Color.white;

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
		var to_x = round(scale * (position.x + to_x_rel - 1))+offset;
		var to_y = round(scale * (position.y + to_y_rel - 1))+offset;
		instance[\queued_screen_ops] = instance[\queued_screen_ops].add(
			{
				Pen.moveTo(from_x@from_y);
				Pen.width = scale;
				Pen.lineTo(to_x@to_y);
			}
		);
	};

	var screen_stroke = { |instance|
		var level = instance[\level];
		var color = instance[\colors][level];
		instance[\queued_screen_ops] = instance[\queued_screen_ops].add(
			{
				Pen.strokeColor = color;
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
	var init_paramset = {
		var params = [];

		var paramset = (
			name: "unnamed"
		);

		paramset.add_ = { |self, arg_param|
			var type = arg_param[\type].asSymbol;
			var id = arg_param[\id].asSymbol;
			var name = arg_param[\name];
			var controlspec = arg_param[\controlspec].asSpec;
			var action = arg_param[\action];
			var formatter = arg_param[\formatter];
			var param;

			if (type != 'control') {
				Error("only params of type 'control' are supported").throw;
			};

			param = ();
			param[\type] = type;
			param[\id] = id;
			param[\name] = name;
			param[\controlspec] = controlspec;
			param[\action] = action;
			param[\formatter] = formatter;
			param[\raw] = if (controlspec.default.notNil) { controlspec.unmap(controlspec.default) } { 0 };
			param.get_ = { |self| // TODO
				self[\controlspec].map(self[\raw])
			};

			params = params.add(param);
		};
		paramset.lookup_param_ = { |self, id|
			params.detect { |param| param[\id] == id.asSymbol };
		};
		paramset.get_name_ = { |self, id|
			var param = self.lookup_param_(id);
			param[\name];
		};
		paramset.set_ = { |self, id, value|
			var param = self.lookup_param_(id);
			param[\raw] = param[\controlspec].unmap(value);
			self.set_raw_(id, param[\controlspec].unmap(value));
		};
		paramset.get_ = { |self, id|
			var param = self.lookup_param_(id);
			param[\controlspec].map(param[\raw]);
		};
		paramset.set_raw_ = { |self, id, value|
			var param = self.lookup_param_(id);
			param[\raw] = value.clip(0, 1);
			param[\action].value(param[\controlspec].map(param[\raw]));
		};
		paramset.get_raw_ = { |self, id|
			var param = self.lookup_param_(id);
			param[\raw];
		};
		paramset.delta_ = { |self, id, d|
			var param = self.lookup_param_(id);
			self.set_raw_(id, param[\raw] + (d/100));
		};
		paramset.bang_ = { |self|
			params.do { |param|
				var value = paramset.get_(param[\id]);
				param[\action].value(value);
			};
		};
		paramset.write = { |self|
			Error("not implemented yet").throw;
		};
		paramset.read_ = { |self|
			Error("not implemented yet").throw;
		};
		paramset.string_ = { |self, id|
			var param = self.lookup_param_(id);
			if (param[\formatter].notNil) {
				param[\formatter].value(param);
			} {
				var a = round(paramset.get_(param[\id]), 0.01);
				a.asString + param[\controlspec].units;
			};
		};
		paramset.list_ = { |self|
			postln("parmset [" ++ self.name ++ "]");
			params.do { |param|
				postln(param[\id]);
			};
		};

		paramset;
	};

	var module = IdentityDictionary[
		\init_paramset -> init_paramset
	];

	module;
}.value;

namespaces.r_engine = {
	var r_path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ ".." +/+ "r.scd").standardizePath;
	var r_api = this.executeFile(r_path);

	var init = r_api[\init];
	var free = r_api[\free];
	var newCommand = r_api[\newCommand];
	var connectCommand = r_api[\connectCommand];
	var disconnectCommand = r_api[\disconnectCommand];
	var deleteCommand = r_api[\deleteCommand];
	var setCommand = r_api[\setCommand];
	var bulksetCommand = r_api[\bulksetCommand];
	var newmacroCommand = r_api[\newmacroCommand];
	var deletemacroCommand = r_api[\deletemacroCommand];
	var macrosetCommand = r_api[\macrosetCommand];
	var readsampleCommand = r_api[\readsampleCommand];
	var tapoutputCommand = r_api[\tapoutputCommand];
	var tapclearCommand = r_api[\tapclearCommand];

	// server booted assumed
	var load_engine = {
		var r_instance;
		var engine;

		r_instance = init.value(
			(
				autostartServer: false,
				trace: false
			)
		);

		engine = ();
		engine.new_ = { |self, name, kind|
			newCommand.value(r_instance, name, kind);
		};
		engine.connect_ = { |self, moduleOutputRef, moduleInputRef|
			connectCommand.value(r_instance, moduleOutputRef, moduleInputRef);
		};
		engine.disconnect_ = { |self, moduleOutputRef, moduleInputRef|
			disconnectCommand.value(r_instance, moduleOutputRef, moduleInputRef);
		};
		engine.delete_ = { |self, moduleRef|
			deleteCommand.value(r_instance, moduleRef);
		};
		engine.set_ = { |self, moduleParameterRef, value|
			setCommand.value(r_instance, moduleParameterRef, value);
		};
		engine.bulkset_ = { |self, bundle|
			bulksetCommand.value(r_instance, bundle);
		};
		engine.newmacro_ = { |self, name, bundle|
			newmacroCommand.value(r_instance, name, bundle);
		};
		engine.deletemacro_ = { |self, name|
			deletemacroCommand.value(r_instance, name);
		};
		engine.macroset_ = { |self, name, value|
			macrosetCommand.value(r_instance, name, value);
		};

		(
			instance: r_instance,
			engine: engine
		)
	};

	var free_engine = { |instance|
		free.value(instance[\r_instance]);
	};

	var module = IdentityDictionary[
		\load_engine -> load_engine,
		\free_engine -> free_engine
	];

	module
}.value;

if (~include_nel_libraries.asBoolean) { // TODO: ugly hack, get around using globals here
	namespaces;
} {
	{
		var screen = namespaces[\screen];
		var init_screen = screen[\init_screen];

		var metro = namespaces[\metro];
		var init_metro = metro[\init_metro];

		var paramset = namespaces[\paramset];
		var init_paramset = paramset[\init_paramset];

		var arc_device_manager = namespaces[\arc_device_manager];
		var init_arc_device_manager = arc_device_manager[\init_arc_device_manager];
		var free_arc_device_manager = arc_device_manager[\free_arc_device_manager];

		var midi_device_manager = namespaces[\midi_device_manager];
		var init_midi_device_manager = midi_device_manager[\init_midi_device_manager];
		var free_midi_device_manager = midi_device_manager[\free_midi_device_manager];

		var grid_device_manager = namespaces[\grid_device_manager];
		var init_grid_device_manager = grid_device_manager[\init_grid_device_manager];
		var free_grid_device_manager = grid_device_manager[\free_grid_device_manager];

/*
	TODO
		var r_engine = namespaces[\r_engine];
		var load_engine = r_engine[\load_engine];
		var free_engine = r_engine[\free_engine];
*/

		var scale = 6;
		var screen_width = 128 * scale;
		var screen_height = 64 * scale;

		var margin_x = 6 * scale;
		var margin_y = 3 * scale;

		var window_width = screen_width + (margin_x*2);
		var window_height = screen_height + (margin_y*2);

		var start_script = { |script_func|
			var script_env;

			var window = Window.new(
				"[Script Name]",
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

			screen_view
				.mouseMoveAction_({false}) // false means: not handled in this view
				.mouseOverAction_({false})
				.mouseDownAction_({false})
				.mouseUpAction_({false})
				;

			window.view
				.onResize_({ |windowView|
					var bounds = windowView.bounds;
					screen_view.moveTo(
						(bounds.width/2)-(screen_view.bounds.width/2),
						(bounds.height/2)-(screen_view.bounds.height/2)
					);
				})
				.onClose_({ |windowView|
					// TODO: stop running routines
					script_env.use {
						~metro.free_all_();
					};
				});

			SerialOSCClient.init {
				var setup_window_mouse_and_key_hooks = {
					var enc_area_pressed = false ! 3;
					var enc_area_prev_pos;
					var key_state = false ! 3;

					var mouse_move_action = { |view, x, y|
						if (enc_area_pressed[0] or: enc_area_pressed[1] or: enc_area_pressed[2]) {
							var delta = enc_area_prev_pos.y - y;
							if (delta != 0) {
								case
									{ enc_area_pressed[0] }
									{
										script_env.use {
											~enc.value(1, delta);
										};
									}
									{ enc_area_pressed[1] }
									{
										script_env.use {
											~enc.value(2, delta);
										};
									}
									{ enc_area_pressed[2] }
									{
										script_env.use {
											~enc.value(3, delta);
										};
									}
									;
								enc_area_prev_pos = x@y;
							};
						};
					};

					var mouse_down_action = { |view, x, y|
						case
							{ in_enc_1_area.value(x, y) }
							{
								enc_area_pressed[0] = true; // 
							}
							{ in_enc_2_area.value(x, y) }
							{
								enc_area_pressed[1] = true;
							}
							{ in_enc_3_area.value(x, y) }
							{
								enc_area_pressed[2] = true;
							};
						enc_area_prev_pos = x@y;
					};

					var mouse_up_action = { |view, x, y|
						enc_area_pressed[0] = false;
						enc_area_pressed[1] = false;
						enc_area_pressed[2] = false;
					};

					var in_enc_1_area = { |x, y|
						(x < (window_width/2)) and: (y < (window_height/2))
					};

					var in_enc_2_area = { |x, y|
						(x < (window_width/2)) and: (y >= (window_height/2))
					};

					var in_enc_3_area = { |x, y|
						(x >= (window_width/2)) and: (y >= (window_height/2))
					};

					window.view
						.mouseMoveAction_(mouse_move_action)
						.acceptsMouseOver_(true)
						.mouseOverAction_(mouse_move_action)
						.mouseDownAction_(mouse_down_action)
						.mouseUpAction_(mouse_up_action)
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
									key_state[0] = true;
									script_env.use {
										~key.value(1, 1);
									};
								}
								{ key_state[0] and: shift_pressed.not }
								{
									key_state[0] = false;
									script_env.use {
										~key.value(1, 0);
									};
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
						});
				};

				script_env = Environment.make {
					// ~engine = engine;

					~screen = screen_api;

					~metro = init_metro.value;
					~params = init_paramset.value;
					~mix = init_paramset.value;
					~midi = init_midi_device_manager.value(currentEnvironment);
					~arc = init_arc_device_manager.value(currentEnvironment);
					~grid = init_grid_device_manager.value(currentEnvironment);

					~mix.add_( // TODO: remove
						(
							type: 'control',
							id: 'output',
							name: "output",
							controlspec: \db.asSpec
						)
					);
					~mix.set_('output', 0);

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
							s.waitForBoot {
								var r_engine_namespace = namespaces[\r_engine];
								var load_engine = r_engine_namespace[\load_engine];
								var free_engine = r_engine_namespace[\free_engine];

								var r_engine = load_engine.value;
								var engine = r_engine[\engine];
								~engine = engine;
								"R engine loaded".debug;
								completeFunc.value;
							};
						}
						{~engine[\name] == 'Ack' } {
							Error("Ack engine not yet supported").throw;
						}
						{ true } {
							"no engine set!".debug;
							completeFunc.value;
						};
					}.value;
				};

				~scripts = ~scripts.add(script_env); // TODO: this goes to the currentEnvironment - check for topEnvironment?
				// TODO 2: call this script_envs since they're environments?

				CmdPeriod.add {
					"script cleanup...".inform;
					script_env.use {
						script_env[\cleanup].value;
					};
					"freeing script device managers...".inform;
					free_script.value(script_env);
					"closing script screen window...".inform;
					window.close;
					"... script successfully freed.".inform;
				};
			};
		};

		var free_script = { |script_env|
			free_midi_device_manager.value(script_env);
			free_arc_device_manager.value(script_env);
			free_grid_device_manager.value(script_env);
		};

		var select_script_environment = { |script_index|
			// TODO: assumes scripts array resides in topEnvironment
			var scripts = topEnvironment[\scripts];
			if (scripts.notNil) {
				var currentScriptEnvIndex = scripts.detectIndex { |script_environment| script_environment == currentEnvironment };
				var script = scripts[script_index];

				if (script.notNil) {
					if (currentScriptEnvIndex.notNil) {
						"script #%'s environment popped".format(currentScriptEnvIndex).inform;
						Environment.pop;
					};
					script.push;
					"script #%'s environment pushed".format(script_index).inform;
				} {
					Error("no script with index % in scripts array!".format(script_index)).throw;
				};
			} {
				Error("no scripts array in topEnvironment!").throw;
			};
		};

		var stop_script = { |script_instance|
			// this should probably be triggered by CmdPeriod
			// call ~cleanup
			// call free_engine
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