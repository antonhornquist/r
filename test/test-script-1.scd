(
var include = { |relative_path|
	var path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ relative_path).standardizePath;
	this.executeFile(path);
};

~init = {
};

~enc = { |n, delta|
	postln("enc" + n + delta);
};

~key = { |n, z|
	postln("key" + n + z);
};

~redraw = {
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
	var lo_level = 5;

	~screen_clear.();
	~screen_font_size.(16);

/*
	TODO
	~screen_level.(hi_level);
	~screen_rect.(enc1_x, enc1_y, 1, 1);
	~screen_rect.(enc1_x, enc1_y-11, 1, 1);
	~screen_fill.();
*/

	~screen_level.(lo_level);
	~screen_move.(enc1_x, enc1_y);
	~screen_text.("LEVEL");

	~screen_level.(hi_level);
	~screen_move.((enc1_x + ~screen_text_extents.("LEVEL") + 3), enc1_y);
	~screen_text.("38");

	~screen_level.(lo_level);
	~screen_rect.(122, enc1_y-7, 5, 5);
	~screen_fill.();

	// param 1
	~screen_level.value(lo_level);
	~screen_move.value(enc2_x, enc2_y);
	~screen_text.value("CUTOFF");

	~screen_level.value(hi_level);
	~screen_move.value(enc2_x, enc2_y+12);
	~screen_text.value("488Hz");

	// visuals
	~screen_level.value(2);
	~screen_rect.value(enc2_x+1 + 9, enc2_y + 14, 5, 2);
	~screen_fill.value;
	~screen_level.value(4);
	~screen_rect.value(enc2_x+1 + 14, enc2_y + 14, 6, 2);
	~screen_fill.();

	// value
	~screen_level.value(hi_level);
	~screen_rect.value(enc2_x+1 + 20, enc2_y + 14, 2, 2);
	~screen_fill.();

	// param 2
	~screen_level.value(lo_level);
	~screen_move.value(enc3_x, enc3_y);
	~screen_text.value("RES");

	~screen_level.value(hi_level);
	~screen_move.value(enc3_x, enc3_y+12);
	~screen_text.value("35%");

	// value
	~screen_level.value(hi_level);
	~screen_rect.value(enc3_x+1 + 10, enc3_y + 14, 2, 2);
	~screen_fill.();

	// page indicator
	~screen_level.value(lo_level);
	~screen_rect.value(1, page_indicator_y, 128/4, 2);
	~screen_fill.();

	// key2
	~screen_level.value(lo_level);
	~screen_move.value(key2_x, key2_y);
	~screen_text.value("PREV");

	// key3
	~screen_level.value(lo_level);
	~screen_move.value(key3_x, key3_y);
	~screen_text.value("NEXT");
};

include.("../util/norns-emu.scd");
)
