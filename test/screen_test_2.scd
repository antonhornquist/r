(
var screen_path = PathName(thisProcess.nowExecutingPath).pathOnly +/+ ".." +/+ "util" +/+ "nel" +/+ "screen.scd";
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

var screen_instance = screen_init.value(window, margin_x, margin_y, scale, colors);

window.view
	.onResize_({ |windowView|
		var bounds = windowView.bounds;
		screen_instance[\view].moveTo(
			(bounds.width/2)-(screen_instance[\view].bounds.width/2),
			(bounds.height/2)-(screen_instance[\view].bounds.height/2)
		);
	});

window.front;

{
	var enc1_x = 1;
	var enc1_y = 12;

	var enc2_x = 10;
	var enc2_y = 29;

	var enc3_x = enc2_x + 65;
	var enc3_y = enc2_y;

	var page_indicator_y = enc2_y + 16 + 3;

	var key2_x = 1;
	var key2_y = 63;

	var key3_x = key2_x+65;
	var key3_y = key2_y;

	var hi_level = 15;
	var lo_level = 4;

	screen_clear.(screen_instance);
	screen_font_size.(screen_instance, 16);

	screen_level.(screen_instance, lo_level);
	screen_move.(screen_instance, enc1_x, enc1_y);
	screen_text.(screen_instance, "LEVEL");

	screen_level.(screen_instance, hi_level);
	screen_move.(screen_instance, (enc1_x + screen_text_extents.(screen_instance, "LEVEL") + 3), enc1_y);
	screen_text.(screen_instance, 57);

	screen_level.(screen_instance, lo_level);
	screen_rect.(screen_instance, 122, enc1_y-7, 5, 5);
	screen_fill.(screen_instance);

	// param 1
	screen_level.(screen_instance, lo_level);
	screen_move.(screen_instance, enc2_x, enc2_y);
	screen_text.(screen_instance, "CUTOFF");

	screen_level.(screen_instance, hi_level);
	screen_move.(screen_instance, enc2_x, enc2_y+12);
	screen_text.(screen_instance, "7.2kHz");

	// visuals
	screen_level.(screen_instance, 2);
	screen_rect.(screen_instance, enc2_x+1 + 9, enc2_y + 14, 5, 2);
	screen_fill.(screen_instance);
	screen_level.(screen_instance, 4);
	screen_rect.(screen_instance, enc2_x+1 + 14, enc2_y + 14, 6, 2);
	screen_fill.(screen_instance);

	// value
	screen_level.(screen_instance, hi_level);
	screen_rect.(screen_instance, enc2_x+1 + 20, enc2_y + 14, 2, 2);
	screen_fill.(screen_instance);

	// param 2
	screen_level.(screen_instance, lo_level);
	screen_move.(screen_instance, enc3_x, enc3_y);
	screen_text.(screen_instance, "RES");

	screen_level.(screen_instance, hi_level);
	screen_move.(screen_instance, enc3_x, enc3_y+12);
	screen_text.(screen_instance, "23%");

	// value
	screen_level.(screen_instance, hi_level);
	screen_rect.(screen_instance, enc3_x+1 + 10, enc3_y + 14, 2, 2);
	screen_fill.(screen_instance);

	// page indicator
	screen_level.(screen_instance, lo_level);
	screen_rect.(screen_instance, 1, page_indicator_y, 128/4, 2);
	screen_fill.(screen_instance);

	// key2
	screen_level.(screen_instance, lo_level);
	screen_move.(screen_instance, key2_x, key2_y);
	screen_text.(screen_instance, "PREV");

	// key3
	screen_level.(screen_instance, lo_level);
	screen_move.(screen_instance, key3_x, key3_y);
	screen_text.(screen_instance, "NEXT");

	screen_update.(screen_instance);
}.value;
)
