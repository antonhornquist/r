(
var norns_engine_tester_path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ "../../util/norns_engine_tester.scd").standardizePath;
var norns_engine_tester = this.executeFile(norns_engine_tester_path);

var start_script = norns_engine_tester[\start_script];

start_script.value {
	~init = {
		var arc_device = ~arc.connect__();
		var grid_device = ~grid.connect__();

		arc_device.led__(1, 1, 15);

		arc_device['delta'] = { |ring, delta|
			[ring, delta].debug(\arc);
			arc_device.all__(1, 0);
			arc_device.led__(1, 64.rand+1, 16.rand);
		};

		grid_device.led__(1, 1, 15);

		grid_device['key'] = { |x, y, s|
			[x, y, s].debug(\grid);
			grid_device.all__(0);
			grid_device.led__(grid_device.cols__.rand+1, grid_device.rows__.rand+1, 16.rand);
		};

		~params.add__(
			(
				type: 'control',
				id: 'cutoff',
				name: "CUTOFF",
				controlspec: \freq.asSpec,
				action: { |value|
					~screen_instance[\redraw] = true;
				},
				formatter: {
				}
			)
		);

		~params.set__('cutoff', 449);
		postln(~params.get__('cutoff'));

		~params.add__(
			(
				type: 'control',
				id: 'res',
				name: "RES",
				controlspec: \unipolar.asSpec,
				action: { |value|
					~screen_instance[\redraw] = true;
				}
			)
		);

		~params.set__('res', 0.25);
		postln(~params.get__('res'));

		"init".debug;
	};

	~enc = { |n, delta|
		postln("enc" + n + delta);
		case
		{n == 2} {
			~params.delta__('cutoff', delta);
		}
		{ n == 3 } {
			~params.delta__('res', delta);
		};
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

		~screen.clear__();
		~screen.font_size__(16);

	/*
		TODO
		~screen_level.(hi_level);
		~screen_rect.(enc1_x, enc1_y, 1, 1);
		~screen_rect.(enc1_x, enc1_y-11, 1, 1);
		~screen_fill.();
	*/

		~screen.level__(lo_level);
		~screen.move__(enc1_x, enc1_y);
		~screen.text__("LEVEL");

		~screen.level__(hi_level);
		~screen.move__((enc1_x + ~screen.text_extents__("LEVEL") + 3), enc1_y);
		~screen.text__(~mix[\get_raw].value('output'));

		~screen.level__(lo_level);
		~screen.rect__(122, enc1_y-7, 5, 5);
		~screen.fill__();

		// param 1
		~screen.level__(lo_level);
		~screen.move__(enc2_x, enc2_y);
		~screen.text__(~params.get_name__('cutoff'));

		~screen.level__(hi_level);
		~screen.move__(enc2_x, enc2_y+12);
		~screen.text__(~params.get__('cutoff').asString ++ "Hz");

		// visuals
		~screen.level__(2);
		~screen.rect__(enc2_x+1 + 9, enc2_y + 14, 5, 2);
		~screen.fill__;
		~screen.level__(4);
		~screen.rect__(enc2_x+1 + 14, enc2_y + 14, 6, 2);
		~screen.fill__();

		// value
		~screen.level__(hi_level);
		~screen.rect__(enc2_x+1 + 20, enc2_y + 14, 2, 2);
		~screen.fill__();

		// param 2
		~screen.level__(lo_level);
		~screen.move__(enc3_x, enc3_y);
		~screen.text__(~params.get_name__('res'));

		~screen.level__(hi_level);
		~screen.move__(enc3_x, enc3_y+12);
		~screen.text__((~params.get__('res')*100).asString ++ "%");

		// value
		~screen.level__(hi_level);
		~screen.rect__(enc3_x+1 + 10, enc3_y + 14, 2, 2);
		~screen.fill__();

		// page indicator
		~screen.level__(lo_level);
		~screen.rect__(1, page_indicator_y, 128/4, 2);
		~screen.fill__();

		// key2
		~screen.level__(lo_level);
		~screen.move__(key2_x, key2_y);
		~screen.text__("PREV");

		// key3
		~screen.level__(lo_level);
		~screen.move__(key3_x, key3_y);
		~screen.text__("NEXT");

		~screen.update__();
	};

	~cleanup = {
		"cleanup".debug;
	};
};
)
