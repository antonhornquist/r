(
var nel_path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ "../../util/nel.scd").standardizePath;
var nel = this.executeFile(nel_path);

var start_script = nel['start_script'];

start_script.value {
	~init = {
		var arc_device = ~arc_connect.();
		var grid_device = ~grid_connect.();

		var percentage_formatter = { |param|
			var value = ~params['get'].(param['id']);
			round(value * 100, 1).asString ++ "%"
		};

		var adaptive_freq_formatter = { |param|
			var hz = ~params['get'].(param['id']);

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
				"-" ++ str[2..str.length] ++ "Hz"
			}
			{ hz < 1 } {
				var str = round(hz, 0.001).asString;
				str[1..str.length] ++ "Hz"
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

		arc_device['led'].(1, 1, 15);

		arc_device['delta'] = { |ring, delta|
			// [ring, delta].debug('arc');
			arc_device[\all].(1, 0);
			arc_device[\led].(1, 64.rand+1, 16.rand);
		};

		grid_device[\led].(1, 1, 15);

		grid_device['key'] = { |x, y, s|
			// [x, y, s].debug(\grid);
			grid_device[\all].(0);
			grid_device[\led].(grid_device[\cols].rand+1, grid_device[\rows].rand+1, 16.rand);
		};

		~params[\add].(
			(
				type: 'control',
				id: 'cutoff',
				name: "CUTOFF",
				controlspec: \freq.asSpec,
				action: { |value|
					~screen_instance[\redraw] = true;
				},
				formatter: adaptive_freq_formatter
			)
		);

		~params[\set].('cutoff', 449);
		postln(~params[\get].('cutoff'));

		~params[\add].(
			(
				type: 'control',
				id: 'res',
				name: "RES",
				controlspec: \unipolar.asSpec,
				action: { |value|
					~screen_instance[\redraw] = true;
				},
				formatter: percentage_formatter
			)
		);

		~params[\set].('res', 0.25);
		postln(~params[\get].('res'));

		"init".debug;
	};

	~enc = { |n, delta|
		//["enc" + n + delta].debug;
		case
		{n == 1} {
			~mix[\delta].('output', delta);
		}
		{n == 2} {
			~params[\delta].('cutoff', delta);
		}
		{ n == 3 } {
			~params[\delta].('res', delta);
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
		~screen_text.(~mix[\get_raw].('output') * 100);

		~screen_level.(lo_level);
		~screen_rect.(122, enc1_y-7, 5, 5);
		~screen_fill.();

		// param 1
		~screen_level.(lo_level);
		~screen_move.(enc2_x, enc2_y);
		~screen_text.(~params[\get_name].('cutoff'));

		~screen_level.(hi_level);
		~screen_move.(enc2_x, enc2_y+12);
		~screen_text.(~params[\string].('cutoff'));

		// visuals
		~screen_level.(2);
		~screen_rect.(enc2_x+1 + 9, enc2_y + 14, 5, 2);
		~screen_fill.();
		~screen_level.(4);
		~screen_rect.(enc2_x+1 + 14, enc2_y + 14, 6, 2);
		~screen_fill.();

		// value
		~screen_level.(hi_level);
		~screen_rect.(enc2_x+1 + 20, enc2_y + 14, 2, 2);
		~screen_fill.();

		// param 2
		~screen_level.(lo_level);
		~screen_move.(enc3_x, enc3_y);
		~screen_text.(~params[\get_name].('res'));

		~screen_level.(hi_level);
		~screen_move.(enc3_x, enc3_y+12);
		~screen_text.((~params[\get].('res')*100).asString ++ "%");

		// value
		~screen_level.(hi_level);
		~screen_rect.(enc3_x+1 + 10, enc3_y + 14, 2, 2);
		~screen_fill.();

		// page indicator
		~screen_level.(lo_level);
		~screen_rect.(1, page_indicator_y, 128/4, 2);
		~screen_fill.();

		// key2
		~screen_level.(lo_level);
		~screen_move.(key2_x, key2_y);
		~screen_text.("PREV");

		// key3
		~screen_level.(lo_level);
		~screen_move.(key3_x, key3_y);
		~screen_text.("NEXT");

		~screen_update.();
	};

	~cleanup = {
		"cleanup".debug;
	};
};
)
