(
var libraries = ();

libraries.arc = {
	// utility library to use a SerialOSCEnc to mock a norns enc, implementing a subset of functions.

	var arc_connect = { |n|
		var arc;

		n = n ? 1; 

		if (n != 1) {
			Error("multiple arcs not supported").throw
		};

		arc = ();
		arc.led_ = { |self, ring, x, val|
			SerialOSCEnc.ringSet(ring-1, x-1, val);
		};
		arc.all_ = { |self, ring, val|
			SerialOSCEnc.ringAll(ring-1, val);
		};

		EncDeltadef( // TODO: use Func, cleanup in a nornsemu_free function
			\nornsemu_encdelta,
			{ |ring, n, delta|
				arc[\delta].value(ring+1, n+1, delta);
			}
		);

		arc;
	};


	var module = IdentityDictionary[
		\arc_connect -> arc_connect,
	];

	module
}.value;

libraries.grid = {
	// utility library to use a SerialOSCGrid to mock a norns grid, implementing a subset of functions.

	var grid_connect = { |n|
		var grid;

		n = n ? 1; 

		if (n != 1) {
			Error("multiple grids not supported").throw
		};

		grid = ();
		grid.led_ = { |self, x, y, val|
			SerialOSCGrid.ledLevelSet(x-1, y-1, val);
		};
		grid.all_ = { |self, val|
			SerialOSCGrid.ledLevelAll(val);
		};
		grid.cols_ = { |self|
			SerialOSCGrid.numCols;
		};
		grid.rows_ = { |self|
			SerialOSCGrid.numRows;
		};

		GridKeydef( // TODO: use Func, cleanup in a nornsemu_free function
			\nornsemu_gridkey,
			{ |x, y, state|
				grid[\key].value(x+1, y+1, state);
			}
		);

		grid;
	};

	var module = IdentityDictionary[
		\grid_connect -> grid_connect,
	];

	module
}.value;

libraries.metro = {
	var init_metro = {
		var metros = [];

		var metro = ();

		metro.init_ = { |self, config|
			var event = config !? _.event;
			var time = (config !? _.time) ? 1;
			var count = (config !? _.count) ? inf;

			metro = ();
			metro[\event] = event;
			metro[\time] = time;
			metro[\count] = count;
			metro[\id] = metros.size;
			metro[\is_running] = false;
			metro.start_ = { |self, time, count|
				if (time.notNil) {
					self[\time] = time;
				};
				if (count.notNil) {
					self[\count] = count;
				};
				metro[\routine] = fork {
					self[\count].do {
						self[\event].value;
						self[\time].wait;
					}
				}
			};
			metro.stop_ = { |self|
				metro[\routine].stop;
			};
			metro.free_ = { |self|
				metros.remove(self);
			};

			metros = metros.add(metro);

			metro;
		};

		metro.free_all = { |self|
			metros.do { |metro|
				metro.free_();
			};
		};

		metro;
	};

	var module = IdentityDictionary[
		\init_metro -> init_metro
	];

	module;
}.value;

libraries.screen = {
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
				// TODO [\Pen, \addRect, Rect(round(scale * x_pos), round(scale * y_pos), round(scale * width), round(scale * height))].debug;
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
				// TODO [\Pen, \moveTo, round(scale * x_pos)@round(scale * y_pos)].debug;
				Pen.moveTo(round(scale * x_pos)@round(scale * y_pos));
			}
		);
	};

	var screen_line = { |instance, x_pos, y_pos|
		var scale = instance[\scale];
		var level = instance[\level];
		x_pos = x_pos - 1;
		y_pos = y_pos - 1;
		instance[\queued_screen_ops] = instance[\queued_screen_ops].add(
			{
				// TODO [\Pen, \width_, scale].debug;
				Pen.width = scale;
				// TODO [\Pen, \lineTo, round(scale * x_pos)@round(scale * y_pos)].debug;
				Pen.lineTo(round(scale * x_pos)@round(scale * y_pos));
			}
		);
	};

	var screen_line_rel = { |instance, x_rel, y_rel|
		var scale = instance[\scale];
		var level = instance[\level];
		var position = instance[\position];
		var x_pos = position.x + x_rel;
		var y_pos = position.y + y_rel;
		instance[\queued_screen_ops] = instance[\queued_screen_ops].add(
			{
				// TODO [\Pen, \width_, scale].debug;
				Pen.width = scale;
				// TODO [\Pen, \lineTo, round(scale * x_pos)@round(scale * y_pos)].debug;
				Pen.lineTo(round(scale * x_pos)@round(scale * y_pos));
			}
		);
	};

	var screen_stroke = { |instance|
		var level = instance[\level];
		var color = instance[\colors][level];
		instance[\queued_screen_ops] = instance[\queued_screen_ops].add(
			{
				// TODO [\Pen, \strokeColor_, color].debug;
				Pen.strokeColor = color;
				// TODO [\Pen, \stroke].debug;
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
				// TODO [\Pen, \font_, instance[\font]].debug;
				Pen.font = instance[\font];
				// TODO [\Pen, \color_, color].debug;
				Pen.color = color;
				// TODO [\Pen, \stringAtPoint, text, round(scale * x_pos)@round(scale * y_pos)].debug;
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
				// TODO [\Pen, \fillColor_, color].debug;
				Pen.fillColor = color;
				// TODO [\Pen, \fill].debug;
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
				// TODO [\Pen, \addRect, Rect(round(scale * x_pos), round(scale * y_pos), round(scale * width), round(scale * height))].debug;
				Pen.addRect(Rect(round(scale * x_pos), round(scale * y_pos), round(scale * width), round(scale * height)));
				// TODO [\Pen, \fillColor_, background_color].debug;
				Pen.fillColor = background_color;
				// TODO [\Pen, \fill].debug;
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

libraries.paramset = {
	var init_paramset = {
		var params = [];

		var paramset = ();

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

		paramset;
	};

	var module = IdentityDictionary[
		\init_paramset -> init_paramset
	];

	module;
}.value;

{
	var screen = libraries[\screen];
	var init_screen = screen[\init_screen];
/*
	var screen_init = screen[\screen_init];
	var screen_rect = screen[\screen_rect];
	var screen_move = screen[\screen_move];
	var screen_line = screen[\screen_line];
	var screen_line_rel = screen[\screen_line_rel];
	var screen_stroke = screen[\screen_stroke];
	var screen_fill = screen[\screen_fill];
	var screen_level = screen[\screen_level];
	var screen_text = screen[\screen_text];
	var screen_text_extents = screen[\screen_text_extents];
	var screen_font_size = screen[\screen_font_size];
	var screen_clear = screen[\screen_clear];
	var screen_update = screen[\screen_update];
*/

	var metro = libraries[\metro];
	var init_metro = metro[\init_metro];

	var paramset = libraries[\paramset];
	var init_paramset = paramset[\init_paramset];

	var arc = libraries[\arc];
	var arc_connect = arc[\arc_connect];

	var grid = libraries[\grid];
	var grid_connect = grid[\grid_connect];

	var engine_path = PathName(thisProcess.nowExecutingPath).pathOnly +/+ "r_engine.scd";
	var engine = this.executeFile(engine_path);
	var load_engine = engine[\load_engine];
	var free_engine = engine[\free_engine];

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
						~enc.value(1, delta);
					}
					{ enc_area_pressed[1] }
					{
						~enc.value(2, delta);
					}
					{ enc_area_pressed[2] }
					{
						~enc.value(3, delta);
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

	var scale = 7;
	var screen_width = 128 * scale;
	var screen_height = 64 * scale;

	var margin_x = 6 * scale;
	var margin_y = 3 * scale;

	var window_width = screen_width + (margin_x*2);
	var window_height = screen_height + (margin_y*2);

	var start_script = { |script_func|
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
						~key.value(1, 1);
					}
					{ key_state[0] and: shift_pressed.not }
					{
						key_state[0] = false;
						~key.value(1, 0);
					}
				;

				case
					{ key_state[1].not and: ctrl_pressed }
					{
						key_state[1] = true;
						~key.value(2, 1);
					}
					{ key_state[1] and: ctrl_pressed.not }
					{
						key_state[1] = false;
						~key.value(2, 0);
					}
				;

				case
					{ key_state[2].not and: alt_pressed }
					{
						key_state[2] = true;
						~key.value(3, 1);
					}
					{ key_state[2] and: alt_pressed.not }
					{
						key_state[2] = false;
						~key.value(3, 0);
					}
				;
			});

		s.waitForBoot {
			var r_engine = load_engine.value;
			~engine = r_engine[\engine];
			~r = r_engine[\library];

			SerialOSCClient.init {
				~screen = screen_api;

				~metro = init_metro.value;
				~params = init_paramset.value;
				~mix = init_paramset.value;

				~arc = ();
				~arc.connect_ = {
					arc_connect.value;
				};

				~grid = ();
				~grid.connect_ = {
					grid_connect.value;
				};

				~mix.add_(
					(
						type: 'control',
						id: 'output',
						name: "output",
						controlspec: \db.asSpec
					)
				);
				~mix.set_('output', 0);


				script_func.value;

				~init.value;
				window.front;
				~redraw.value;
			};
		};

		~window = window;
	};

	var stop_script = { |script_instance|
		// this should probably be triggered by CmdPeriod
		// call ~cleanup
	};

	var module = IdentityDictionary[
		\start_script -> start_script,
		\stop_script -> stop_script
	];

	module;
}.value;
)
