(
var screen_path = PathName(thisProcess.nowExecutingPath).pathOnly +/+ "nel" +/+ "screen.scd";
var screen = this.executeFile(screen_path);
var screen_init = screen[\screen_init];
var screen_rect = screen[\screen_rect];
var screen_move = screen[\screen_move];
var screen_line = screen[\screen_line];
var screen_stroke = screen[\screen_stroke];
var screen_fill = screen[\screen_fill];
var screen_level = screen[\screen_level];
var screen_text = screen[\screen_text];
var screen_text_extents = screen[\screen_text_extents];
var screen_font_size = screen[\screen_font_size];
var screen_clear = screen[\screen_clear];
var screen_update = screen[\screen_update];

var paramset_path = PathName(thisProcess.nowExecutingPath).pathOnly +/+ "nel" +/+ "paramset.scd";
var paramset = this.executeFile(paramset_path);
var init_paramset = paramset[\init_paramset];

var arc_path = PathName(thisProcess.nowExecutingPath).pathOnly +/+ "nel" +/+ "arc.scd";
var arc = this.executeFile(arc_path);
var arc_connect = arc[\arc_connect];

var grid_path = PathName(thisProcess.nowExecutingPath).pathOnly +/+ "nel" +/+ "grid.scd";
var grid = this.executeFile(grid_path);
var grid_connect = grid[\grid_connect];

var enc_area_pressed = false ! 3;
var enc_area_prev_pos;
var key_state = false ! 3;

var create_screen_and_inject_globals = { |parent_view, x, y, scale|
	var screen_instance = screen_init.value(parent_view, x, y, scale, {
		screen_instance[\redraw] = false;
		~redraw.value;
		if (screen_instance[\redraw]) {
			defer { screen_instance[\view].refresh };
		};
	});

	~screen_rect = { |x, y, width, height|
		screen_rect.value(screen_instance, x, y, width, height);
	};

	~screen_move = { |x, y|
		screen_move.value(screen_instance, x, y);
	};

	~screen_line = { |x, y|
		screen_line.value(screen_instance, x, y);
	};

	~screen_stroke = {
		screen_stroke.value(screen_instance);
	};

	~screen_fill = {
		screen_fill.value(screen_instance);
	};

	~screen_level = { |level|
		screen_level.value(screen_instance, level);
	};

	~screen_text = { |text|
		screen_text.value(screen_instance, text);
	};

	~screen_text_extents = { |text|
		screen_text_extents.value(screen_instance, text);
	};

	~screen_font_size = { |size|
		screen_font_size.value(screen_instance, size);
	};

	~screen_clear = {
		screen_clear.value(screen_instance);
	};

	~screen_update = {
		screen_update.value(screen_instance);
	};

	~screen_instance = screen_instance; // TODO

	screen_instance[\view]
};

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
			enc_area_pressed[0] = true;
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
/*
	case
		{ in_enc_1_area.value(x, y) }
		{
			enc_area_pressed[0] = false;
		}
		{ in_enc_2_area.value(x, y) }
		{
			enc_area_pressed[1] = false;
		}
		{ in_enc_3_area.value(x, y) }
		{
			enc_area_pressed[2] = false;
		};
*/
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

var scale = 4;
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

	var screen_view = create_screen_and_inject_globals.value(window, margin_x, margin_y, scale); // TODO: do not inject globals in screen.scd, instead do it here.

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

	SerialOSCClient.init {
		~params = init_paramset.value;

		~mix = init_paramset.value;
		~mix[\add].value(
			(
				type: 'control',
				id: 'output',
				name: "output",
				controlspec: \db.asSpec
			)
		);
		~mix[\set].value('output', 0);

		~arc_connect = arc_connect;
		~grid_connect = grid_connect;

		script_func.value;

		~init.value;
		window.front;
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

module
)
