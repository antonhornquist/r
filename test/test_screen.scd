(
var screen_path = PathName(thisProcess.nowExecutingPath).pathOnly +/+ ".." +/+ "util" +/+ "norns_engine_tester" +/+ "screen.scd";
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

var scale = 4;
var screen_width = 128 * scale;
var screen_height = 64 * scale;

var margin_x = 6 * scale;
var margin_y = 3 * scale;

var window_width = screen_width + (margin_x*2);
var window_height = screen_height + (margin_y*2);

var window = Window.new(
	"screen test",
	Rect(
		Window.screenBounds.width - window_width - 25,
		Window.screenBounds.height - window_height - 50,
		window_width,
		window_height
	))
	.background_(Color.black);

var screen_instance = screen_init.value(window, x, y, scale, {
	var queued_screen_ops = screen_instance[\queued_screen_ops];
\drawFunc.debug;
	queued_screen_ops.do { |screen_op, i|
[i, screen_op].debug(\screen_op);

		screen_op.value;
	};
	screen_instance[\queued_screen_ops] = [];
});

~screen_instance = screen_instance; // TODO

~screen_rect = screen_rect;
~screen_move = screen_move;
~screen_line = screen_line;
~screen_stroke = screen_stroke;
~screen_fill = screen_fill;
~screen_level = screen_level;
~screen_text = screen_text;
~screen_text_extents = screen_text_extents;
~screen_font_size = screen_font_size;
~screen_clear = screen_clear;
~screen_update = screen_update;

window.view
	.onResize_({ |windowView|
		var bounds = windowView.bounds;
		screen_instance[\view].moveTo(
			(bounds.width/2)-(screen_instance[\view].bounds.width/2),
			(bounds.height/2)-(screen_instance[\view].bounds.height/2)
		);
	});

window.front;
)
