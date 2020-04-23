(
var screen_path = PathName(thisProcess.nowExecutingPath).pathOnly +/+ "screen.scd";
var screen = this.executeFile(screen_path);

var params_path = PathName(thisProcess.nowExecutingPath).pathOnly +/+ "params.scd";
var params = this.executeFile(params_path);

var init_params = params[\init_params];

var arc_path = PathName(thisProcess.nowExecutingPath).pathOnly +/+ "arc.scd";
var arc = this.executeFile(arc_path);
var arc_connect = arc[\arc_connect];

var grid_path = PathName(thisProcess.nowExecutingPath).pathOnly +/+ "grid.scd";
var grid = this.executeFile(grid_path);
var grid_connect = grid[\grid_connect];

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

var global_screen_init = screen[\global_screen_init];

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

	global_screen_init.value(window, margin_x, margin_y, scale); // TODO: do not inject globals in screen.scd, instead do it here.

	~screen[\view]
		.mouseMoveAction_({false}) // false means: not handled in this view
		.mouseOverAction_({false})
		.mouseDownAction_({false})
		.mouseUpAction_({false})
		;

	window.view
		.onResize_({ |windowView|
			var bounds = windowView.bounds;
			var view = ~screen[\view];
			view.moveTo(
				(bounds.width/2)-(view.bounds.width/2),
				(bounds.height/2)-(view.bounds.height/2)
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
		~params = init_params.value;
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
