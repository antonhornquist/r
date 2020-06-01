(
var include_relative = { |relative_path|
	var path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ relative_path).standardizePath;
	if (File.exists(path)) {
		this.executeFile(path);
	} {
		Error("include_relative: file % does not exist".format(path.quote)).throw;
	};
};

var init_screen = {
	var libraries;
	var screen_library;
	~include_nel_libraries = true;
	libraries = include_relative.value("../util/norns_engine_tester.scd");
	screen_library = libraries[\screen];
	screen_library[\init_screen];
}.value;

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

var screen;
var view;

# screen, view = {
	var screen = init_screen.value(window, margin_x, margin_y, scale);
	[ screen[\singleton], screen[\view] ];
}.value;

window.view
	.onResize_({ |windowView|
		var bounds = windowView.bounds;
		view.moveTo(
			(bounds.width/2)-(view.bounds.width/2),
			(bounds.height/2)-(view.bounds.height/2)
		);
	});

window.front;

{
	fork {
inf.do { |fdsa|
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

	screen.clear_();
	screen.font_size_(16);

	screen.level_(lo_level);
	screen.move_(enc1_x, enc1_y);
	screen.text_("LEVEL");

	screen.level_(hi_level);
	screen.move_((enc1_x + screen.text_extents_("LEVEL") + 3), enc1_y);
	screen.text_(57);

4.do {
	screen.level_(lo_level);
	screen.rect_(122, enc1_y-7, 5, 5);
	screen.fill_();
};

	// param 1
	screen.level_(lo_level);
	screen.move_(enc2_x, enc2_y);
	screen.text_("CUTOFF");

	screen.level_(hi_level);
	screen.move_(enc2_x, enc2_y+12);
	screen.text_("7.2kHz");

	// visuals
	screen.level_(2);
	screen.rect_(enc2_x+1 + 9, enc2_y + 14, 5, 2);
	screen.fill_();
	screen.level_(4);
	screen.rect_(enc2_x+1 + 14, enc2_y + 14, 6, 2);
	screen.fill_();

	// value
	screen.level_(hi_level);
	screen.rect_(enc2_x+1 + 20, enc2_y + 14, 2, 2);
	screen.fill_();

	// param 2
	screen.level_(lo_level);
	screen.move_(enc3_x, enc3_y);
	screen.text_("RES");

	screen.level_(hi_level);
	screen.move_(enc3_x, enc3_y+12);
	screen.text_("23%");

	// value
	screen.level_(hi_level);
	screen.rect_(enc3_x+1 + 10, enc3_y + 14, 2, 2);
	screen.fill_();

	// page indicator
	screen.level_(lo_level);
	screen.rect_(1, page_indicator_y, 128/4, 2);
	screen.fill_();

	// key2
	screen.level_(lo_level);
	screen.move_(key2_x, key2_y);
	screen.text_("PREV");

	// key3
	screen.level_(lo_level);
	screen.move_(key3_x, key3_y);
	screen.text_("NEXT");

	screen.update_();

fdsa.debug;
(1/35).wait;
};
	};
}.value;
)
