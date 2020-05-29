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
	var ui_event_indicator_shown = ui[\event_indicator_shown];

	var r_specs = include_relative.value("lib/r_specs.scd");

	var ppqn = 24;
	var count;
	var playing=false;
	var tempo_spec = ControlSpec.new(20, 300, 'lin', 0, 120, "BPM");
	var sequencer_metro;

	var recent_midi_cc_events = [];

	var reset_counter = {
		count = 0;
	};

	var tick = {
		count = count + 1;
		ui_set_dirty.value();
	};

	var update_sequencer_metro_time = {
		sequencer_metro.time = 60/~params.get_("tempo")/ppqn;
	};

	var init_sequencer_metro = {
		sequencer_metro = ~metro.init_();
		update_sequencer_metro_time.value();
		sequencer_metro.event = tick;
	};

	var start_sequencer = {
		playing = true;
		sequencer_metro.start_();
	};

	var stop_sequencer = {
		playing = false;
		sequencer_metro.stop_();
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
					ui_set_dirty.value();
				}
			)
		);
	};

	var init_60_fps_ui_refresh_metro = {
		var ui_refresh_metro = ~metro.init_();
		ui_refresh_metro[\event] = ui_refresh;
		ui_refresh_metro.time = 1/60;
		ui_refresh_metro.start_();
	};

	var init_ui = {
		ui_init_arc.value(
			(
				device: ~arc.connect_(),
				on_delta: { |n, delta|
					[n, delta].debug(\arc_on_delta);
					case {n == 1} {
						var val = ~params.get_raw_("tempo");
						~params.set_raw_("tempo", val+(delta/500))
					;}
				},
				on_refresh: { |my_arc|
					"arc_refresh".debug;
/*
					my_arc.all_(0);
					my_arc.led_(1, round(~params.get_raw_("tempo")*64).round, 15);
*/
				}
			)
		);

		ui_init_grid.value(
			(
				device: ~grid.connect_(),
				on_key: { |x, y, state|
					// [x, y, state].debug(\grid_on_key);
					ui_set_dirty.value()
				},
				on_refresh: { |my_grid|
					"grid_refresh".debug;
					my_grid.led_(8.rand+1, 8.rand+1, 15);
				},
			)
		);

		ui_init_midi.value(
			(
				device: ~midi.connect_(),
				on_event: { |data|
					data.debug(\midi_on_event);
					if (data[\type] == 'cc') {
						var val = data[\val];
						var delta = if (val > 64, val - 128, val);
						recent_midi_cc_events = recent_midi_cc_events.addFirst("cc"++data[\num]++": "++delta);
						if (recent_midi_cc_events.size > 5) {
							recent_midi_cc_events.removeAt(5);
						};
						case
						{data[\num] == 1} {
							~params.delta_("tempo", delta);
						};
						ui_set_dirty.value()
					};
				},
			)
		);

		ui_init_screen.value(
			(
				on_refresh: {
					"screen_refresh".debug;
					// TODO my_screen.debug(\screen_on_refresh);
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
		reset_counter.value();
		// start_sequencer.value();

		~params.bang_();
	};

	~redraw = {
		~screen.clear_();
		~screen.font_size_(8);

		~screen.level_(15);

		~screen.move_(1, 10);
		~screen.text_("TEST_UI");

		if (ui_event_indicator_shown.value) {
			~screen.move_(50, 10);
			~screen.text_("EXT");
		};

		{
			var y = 18;
			recent_midi_cc_events.do { |ev, idx|
				~screen.move_(1, y + (idx*8));
				~screen.level_(15 - ((15 / 5)*idx));
				~screen.text_(ev);
			}
		}.value;

		~screen.level_(15);
		~screen.move_(32, 30);
		~screen.text_((count div: (ppqn*4)).asString ++ "." ++ ((count div: ppqn) mod: 4).asString ++ "." ++ (count mod: ppqn).asString);

		~screen.move_(1, 64);
		~screen.text_("TEMPO" + ~params.string_("tempo"));

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
				reset_counter.value();
			} {
				stop_sequencer.value();
			};
		}
		{(n == 3) and: (s == 1)} {
			if (playing == false) {
				start_sequencer.value();
			};
		};
		ui_set_dirty.value();
	};

};
)
