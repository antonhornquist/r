(
var include_relative = { |relative_path|
	var path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ relative_path).standardizePath;
	this.executeFile(path);
};

var norns_engine_tester = include_relative.value("../util/norns_engine_tester.scd");
var start_script = norns_engine_tester['start_script'];

start_script.value {
	var ui = include_relative.value("lib/ui.scd");
	var ui_init_arc = ui[\init_arc];
	var ui_init_screen = ui[\init_screen];
	var ui_init_grid = ui[\init_grid];
	var ui_init_midi = ui[\init_midi];
	var ui_grid_width = ui[\grid_width];
	var ui_refresh = ui[\refresh];
	var ui_set_dirty = ui[\set_dirty];

	var r_specs = include_relative.value("lib/r_specs.scd");

	var ppqn = 24;
	var playpos=0;
	var playing=false;
	var tempo_spec = ControlSpec.new(20, 300, 'lin', 0, 120, "BPM");
	var sequencer_metro;

	var tick = {
		playpos = playpos + 1;
		postln(playpos);
	};

	var update_sequencer_metro_time = {
		sequencer_metro.time = 60/~params.get_("tempo")/ppqn;
	};

	var init_sequencer_metro = {
		sequencer_metro = ~metro.init_();
		update_sequencer_metro_time.value();
		sequencer_metro.event = tick;
	};

	var init_params = {
		~params.add_( 
			(
				type: "control",
				id: "tempo",
				name: "Tempo",
				controlspec: tempo_spec,
				action: { |val|
					update_sequencer_metro_time.value(val);
					ui_set_dirty.value;
				}
			)
		);
	};

	var init_60_fps_ui_refresh_metro = {
		var ui_refresh_metro = ~metro.init_();
		ui_refresh_metro.event = ui_refresh;
		ui_refresh_metro.time = 1/60;
		ui_refresh_metro.start_();
	};

	var init_ui = {
		ui_init_arc.value(
			(
				device: ~arc.connect_(),
				delta_callback: { |n, delta|
					case {n == 1} {
						var val = ~params.get_raw_("tempo");
						~params.set_raw_("tempo", val+delta/500)
					;}
				},
				refresh_callback: { |my_arc|
					my_arc.all_(0);
					my_arc.led_(1, round(~params.get_raw_("tempo")*64).round, 15);
				}
			)
		);

		ui_init_grid.value(
			(
				device: ~grid.connect_(),
				key_callback: { |x, y, state|
					[x, y, state].debug;
					ui_set_dirty.value()
				},
				refresh_callback: { |my_grid|
					"grid_refresh".debug;
				},
			)
		);

		ui_init_screen.value(
			(
				refresh_callback: {
					~redraw.value();
				}
			)
		);

		init_60_fps_ui_refresh_metro.value();
	};

	~engine.name = 'R';

	~init = {
		init_params.value();
		init_sequencer_metro.value();
		init_ui.value();
		playing = true;
		sequencer_metro.start_();

		~params.bang_();
	};

	~redraw = {
		~screen.clear_();
		~screen.font_size_(8);

		~screen.level_(15);
		~screen.move_(1, 10);
		~screen.text_("TEST_UI");

		~screen.update_();
	};

	~enc = { |n, delta|
		case
		{n == 2} {
			~params.delta_("tempo", delta);
		};
	};

	~key = { |n, s|
		case
		{(n == 2) and: (s == 1)} {
			if (playing == false) {
				playpos = -1;
			} {
				playing = false;
				sequencer_metro.stop_();
			};
		}
		{(n == 2) and: (s == 1)} {
			playing = true;
			sequencer_metro.start_();
		};
		ui_set_dirty.value();
	};

};
)
