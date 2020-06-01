(
var include_relative = { |relative_path|
	var path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ relative_path).standardizePath;
	if (File.exists(path)) {
		this.executeFile(path);
	} {
		Error("include_relative: file % does not exist".format(path.quote)).throw;
	};
};

var norns_engine_tester = include_relative.value("../util/norns_engine_tester.scd");
var start_script = norns_engine_tester['start_script'];

start_script.value {
	~init = {
		var arc_device = ~arc.connect_();
		var grid_device = ~grid.connect_();

		var percentage_formatter = { |param|
			var value = ~params.get_(param['id']);
			round(value * 100, 1).asString ++ "%"
		};

		var adaptive_freq_formatter = { |param|
			var hz = ~params.get_(param['id']);

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
		arc_device.led_(1, 1, 15);

		arc_device['delta'] = { |ring, delta|
			// [ring, delta].debug('arc');
			arc_device.all_(ring, 0);
			arc_device.led_(ring, 64.rand+1, 16.rand);

			if (ring == 1) {
				var val = ~params.get_raw_('cutoff');
				~params.set_raw_('cutoff', val+(delta/500));
			} {
				var val = ~params.get_raw_('res');
				~params.set_raw_('res', val+(delta/500));
			};
		};

		grid_device.led_(1, 1, 15);

		grid_device['key'] = { |x, y, s|
			// [x, y, s].debug(\grid);
			grid_device.all_(0);
			grid_device.led_(grid_device.cols_().rand+1, grid_device.rows_().rand+1, 16.rand);
		};

		~midi_device = ~midi.connect_();
		~midi_device.event = { |data|
			case
			{ (data.type == 'cc') and: (data.num ==1) } {
				~params.set_raw_("cutoff", data.val/127);
			}
			{ (data.type == 'cc') and: (data.num ==2) } {
				~params.set_raw_("res", data.val/127);
			};
		};

		~params.add_(
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

		~params.add_(
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

		~params.set_('cutoff', 449);
		~params.set_('res', 0.25);

		"init".debug;
	};

	~enc = { |n, delta|
		//["enc" + n + delta].debug;
		case
		{n == 1} {
			~mix.delta_('output', delta);
			~redraw.value;
		}
		{n == 2} {
			~params.delta_('cutoff', delta);
		}
		{ n == 3 } {
			~params.delta_('res', delta);
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

		~screen.clear_();
		~screen.font_size_(16);

		~screen.level_(lo_level);
		~screen.move_(enc1_x, enc1_y);
		~screen.text_("LEVEL");

		~screen.level_(hi_level);
		~screen.move_((enc1_x + ~screen.text_extents_("LEVEL") + 3), enc1_y);
		~screen.text_(round(~mix.get_raw_('output')*100));

		~screen.level_(lo_level);
		~screen.rect_(122, enc1_y-7, 5, 5);
		~screen.fill_();

		// param 1
		~screen.level_(lo_level);
		~screen.move_(enc2_x, enc2_y);
		~screen.text_(~params.get_name_('cutoff'));

		~screen.level_(hi_level);
		~screen.move_(enc2_x, enc2_y+12);
		~screen.text_(~params.string_('cutoff'));

		// visuals
		~screen.level_(2);
		~screen.rect_(enc2_x+1 + 9, enc2_y + 14, 5, 2);
		~screen.fill_;
		~screen.level_(4);
		~screen.rect_(enc2_x+1 + 14, enc2_y + 14, 6, 2);
		~screen.fill_();

		// value
		~screen.level_(hi_level);
		~screen.rect_(enc2_x+1 + 20, enc2_y + 14, 2, 2);
		~screen.fill_();

		// param 2
		~screen.level_(lo_level);
		~screen.move_(enc3_x, enc3_y);
		~screen.text_(~params.get_name_('res'));

		~screen.level_(hi_level);
		~screen.move_(enc3_x, enc3_y+12);
		~screen.text_(~params.string_('res'));

		// value
		~screen.level_(hi_level);
		~screen.rect_(enc3_x+1 + 10, enc3_y + 14, 2, 2);
		~screen.fill_();

		// page indicator
		~screen.level_(lo_level);
		~screen.rect_(1, page_indicator_y, 128/4, 2);
		~screen.fill_();

		// key2
		~screen.level_(lo_level);
		~screen.move_(key2_x, key2_y);
		~screen.text_("PREV");

		// key3
		~screen.level_(lo_level);
		~screen.move_(key3_x, key3_y);
		~screen.text_("NEXT");

		~screen.update_();
	};

	~cleanup = {
		"cleanup".debug;
	};
};
)
