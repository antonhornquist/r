(
var screen_path = PathName(thisProcess.nowExecutingPath).pathOnly +/+ ".." +/+ ".." +/+ ".." +/+ "util" +/+ "nel" +/+ "screen.scd";
var screen = this.executeFile(screen_path);

var scale = 4;
var screen_width = 128 * scale;
var screen_height = 64 * scale;

var margin_x = 6 * scale;
var margin_y = 3 * scale;

var window_width = screen_width + (margin_x*2);
var window_height = screen_height + (margin_y*2);

var background_color = Color.black;
var foreground_color = Color.white;

/*
TODO
var num_levels = 16;
var colors = num_levels.collect { |level|
	background_color.blend(foreground_color, level/(num_levels-1));
};
*/
var colors = [0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 1].collect { |level| background_color.blend(foreground_color, level) };

var window = Window.new(
	"screen test",
	Rect(
		Window.screenBounds.width - window_width - 25,
		Window.screenBounds.height - window_height - 50,
		window_width,
		window_height
	))
	.background_(colors[0]);

~screen_init = screen[\screen_init];
~screen_rect = screen[\screen_rect];
~screen_move = screen[\screen_move];
~screen_line = screen[\screen_line];
~screen_stroke = screen[\screen_stroke];
~screen_fill = screen[\screen_fill];
~screen_level = screen[\screen_level];
~screen_text = screen[\screen_text];
~screen_text_extents = screen[\screen_text_extents];
~screen_font_size = screen[\screen_font_size];
~screen_clear = screen[\screen_clear];
~screen_update = screen[\screen_update];

~screen_instance = ~screen_init.value(window, margin_x, margin_y, scale, colors);

window.view
	.onResize_({ |windowView|
		var bounds = windowView.bounds;
		~screen_instance[\view].moveTo(
			(bounds.width/2)-(~screen_instance[\view].bounds.width/2),
			(bounds.height/2)-(~screen_instance[\view].bounds.height/2)
		);
	});

window.front;
)

(
~screen_move.(~screen_instance, 1, 8);
~screen_level.(~screen_instance, 15);
~screen_font_size.(~screen_instance, 8);
~screen_text.(~screen_instance, "test");
~screen_update.(~screen_instance);
)

(
~screen_move.(~screen_instance, 1, 16);
~screen_level.(~screen_instance, 5);
~screen_font_size.(~screen_instance, 16);
~screen_text.(~screen_instance, "R");
~screen_update.(~screen_instance);
)

(
~screen_clear.(~screen_instance);
~screen_update.(~screen_instance);
)

(
~screen_clear.(~screen_instance);
16.do { |index|
	~screen_level.(~screen_instance, index);
	~screen_rect.(~screen_instance, index, index, index, index);
	~screen_fill.(~screen_instance);
};
~screen_update.(~screen_instance);
)
