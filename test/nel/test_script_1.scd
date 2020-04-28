(
var nel_path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ "../../util/nel.scd").standardizePath;
var nel = this.executeFile(nel_path);

var start_script = nel['start_script'];

start_script.value {
	~init = {
		var arc_device = ~arc.connect__();
		var grid_device = ~grid.connect__();

		var percentage_formatter = { |param|
			var value = ~params.get__(param['id']);
			round(value * 100, 1).asString ++ "%"
		};

		var adaptive_freq_formatter = { |param|
			var hz = ~params.get__(param['id']);

			case
			{ hz <= -1000 } {
				round(hz/1000, 0.1).asString ++ "kHz"
			}
			{ hz <= -100 } {
				round(hz, 1).asString ++ "Hz"
			}
			{ hz <= -10 } {
				round(hz, 0.1).asString ++ "Hz"
			}
			{ hz <= -1 } {
				round(hz, 0.01).asString ++ "Hz"
			}
			{ hz < 0 } {
				var str = round(hz, 0.001).asString;
				"-" ++ str[2..str.length] ++ "Hz"
			}
			{ hz < 1 } {
				var str = round(hz, 0.001).asString;
				str[1..str.length] ++ "Hz"
			}
			{ hz < 10 } {
				round(hz, 0.01).asString ++ "Hz"
			}
			{ hz < 100 } {
				round(hz, 0.1).asString ++ "Hz"
			}
			{ hz < 1000 } {
				round(hz, 1).asString ++ "Hz"
			}
			{ hz < 10000 } {
				round(hz/1000, 0.1).asString ++ "kHz"
			}
			{ true } {
				round(hz/1000, 1).asString ++ "kHz"
			}
		};

		arc_device.led__(1, 1, 15);

		arc_device['delta'] = { |ring, delta|
			// [ring, delta].debug('arc');
			arc_device.all__(ring, 0);
			arc_device.led__(ring, 64.rand+1, 16.rand);

			if (ring == 1) {
				var val = ~params.get_raw__('cutoff');
				~params.set_raw__('cutoff', val+(delta/500));
			} {
				var val = ~params.get_raw__('res');
				~params.set_raw__('res', val+(delta/500));
			};
		};

		grid_device.led__(1, 1, 15);

		grid_device['key'] = { |x, y, s|
			// [x, y, s].debug(\grid);
			grid_device.all__(0);
			grid_device.led__(grid_device.cols__().rand+1, grid_device.rows__().rand+1, 16.rand);
		};

		~params.add__(
			(
				type: 'control',
				id: 'cutoff',
				name: "CUTOFF",
				controlspec: \freq.asSpec,
				action: { |value|
					~redraw.value;
				},
				formatter: adaptive_freq_formatter
			)
		);

		~params.set__('cutoff', 449);

		~params.add__(
			(
				type: 'control',
				id: 'res',
				name: "RES",
				controlspec: \unipolar.asSpec,
				action: { |value|
					~redraw.value;
				},
				formatter: percentage_formatter
			)
		);

		~params.set__('res', 0.25);

		"init".debug;
	};

	~enc = { |n, delta|
		//["enc" + n + delta].debug;
		case
		{n == 1} {
			~mix.delta__('output', delta);
			~redraw.value;
		}
		{n == 2} {
			~params.delta__('cutoff', delta);
		}
		{ n == 3 } {
			~params.delta__('res', delta);
		};
	};

	~key = { |n, z|
		//["key" + n + z].debug;
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
		~screen.text__(round(~mix.get_raw__('output')*100));

		~screen.level__(lo_level);
		~screen.rect__(122, enc1_y-7, 5, 5);
		~screen.fill__();

		// param 1
		~screen.level__(lo_level);
		~screen.move__(enc2_x, enc2_y);
		~screen.text__(~params.get_name__('cutoff'));

		~screen.level__(hi_level);
		~screen.move__(enc2_x, enc2_y+12);
		~screen.text__(~params.string__('cutoff'));

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
		~screen.text__(~params.string__('res'));

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
