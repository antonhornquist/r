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
	// scriptname: moln
	// v1.3.0 @jah
	var r_moln = include_relative.value('lib/r_moln.scd');
	var r_moln_init = r_moln[\init];
	var r_moln_note_on = r_moln[\note_on];
	var r_moln_note_off = r_moln[\note_off];

	var formatters = include_relative.value("lib/formatters.scd");

	var common = include_relative.value("lib/common.scd");
	var common_init = common[\init];
	var common_cleanup = common[\cleanup];
	var common_redraw = common[\redraw];
	var common_enc = common[\enc];
	var common_key = common[\key];
	var common_set_ui_dirty = common[\set_ui_dirty];
	var common_mouse = common[\mouse];

	var settings_file = "moln.data";
	var ui_refresh_rate = 35;

	var script_context;

	var engine_ready = false;

	var start_after_1_second_delay; // TODO: global in lua
	var init_engine_init_delay_metro; // TODO: global in lua

	~engine.name = 'R';

	~init = {
		var r_moln_instance = r_moln_init.value(
			(
				engine_global: ~engine,
				visual_buf_size: round(ui_refresh_rate/20)
			)
		);

		var ui_spec = (
			arc: ( device: ~arc.connect_() ),
			midi: (
				device: ~midi.connect_(),
				on_event: { |data|
					if (engine_ready) {
						var msg = ~midi.to_msg_(data);
						case
						{msg['type'] == 'note_off'} {
							r_moln_note_off.value(~engine, msg.note);
						}
						{msg['type'] == 'note_on'} {
							r_moln_note_on.value(~engine, msg.note, msg.vel / 127);

						}
						{msg['type'] == 'cc'} {
							var num = msg['num'];
							var val = msg['val'];
							var rel_cc_delta = if (val > 64, val-128, val);
							[num, val].debug;
							case
							{num == 1} {
								// ~params.delta_( "lfo_frequency", rel_cc_delta);
								common_enc.value(2, rel_cc_delta);
							}
							{num == 2} {
								//~params.delta_( "lfo_to_osc_pwm", rel_cc_delta);
								//~params.delta_( "osc_detune", rel_cc_delta);
								common_enc.value(3, rel_cc_delta);
							}
							{num == 3} {
								// ~params.delta_( "filter_frequency", rel_cc_delta);
							}
							{num == 4} {
								//~params.delta_( "env_release", rel_cc_delta);
								common_enc.value(1, rel_cc_delta);
							}
							{num == 11} {
								case
								{val == 127} {
									common_key.value(2, 1);
								}
								{val == 0} {
									common_key.value(2, 0);
								};
							}
							{num == 12} {
								case
								{val == 127} {
									common_key.value(3, 1);
								}
								{val == 0} {
									common_key.value(3, 0);
								};
							}
							{num == 14} {
								case
								{val == 127} {
									common_key.value(1, 1);
								}
								{val == 0} {
									common_key.value(1, 0);
								};
							}
							;
							common_set_ui_dirty.value();
						};
					}
				}
			),
			pages: [
				[ (id: "filter_frequency"), (id: "filter_resonance") ],
				[ (id: "osc_a_range"), (id: "osc_b_range") ],
				[ (id: "osc_a_pulsewidth"), (id: "osc_b_pulsewidth") ],
				[ (id: "osc_detune"), (id: "lfo_frequency") ],
				[ (id: "lfo_to_osc_pwm"), (id: "env_to_filter_fm") ],
				[ (id: "env_attack"), (id: "env_decay") ],
				[ (id: "env_sustain"), (id: "env_release") ],
			],
			refresh_rate: ui_refresh_rate
		);

		script_context = common_init.value(
			(
				globals: (
					screen: ~screen,
					metro: ~metro,
					params: ~params,
					poll: ~poll,
					redraw: ~redraw
				),
				param_specs: r_moln_instance[\param_specs],
/*
	TODO
				poll_specs: r_moln_instance[\poll_specs],
				visual_values: r_moln_instance[\visual_values],
*/
				ui_spec: ui_spec,
				settings_file: settings_file,
			)
		);

		start_after_1_second_delay.value(r_moln_instance);
	};

	start_after_1_second_delay = { |r_moln_instance|
		init_engine_init_delay_metro.value();
	};

	init_engine_init_delay_metro = {
		var engine_init_delay_metro = ~metro.init_();
		engine_init_delay_metro[\event] = {
			engine_ready = true;

			common_set_ui_dirty.value();

			engine_init_delay_metro.stop_();
		};
		engine_init_delay_metro.time = 1;
		engine_init_delay_metro.start_();
	};

/*
	TODO
	~cleanup = {
		common_cleanup.value(settings_file);
	};
*/

	~redraw = {
		common_redraw.value(script_context);
	};

/*
	TODO
	~enc = { |n, delta|
		common_enc.value(n, delta);
	};
*/

	~key = { |n, z|
		if (n == 1) {
			if (z == 1) {
				[60, 63, 67] do: { |note|
					r_moln_note_on.value(~engine, note, 1);
				};
			} {
				[60, 63, 67] do: { |note|
					r_moln_note_off.value(~engine, note);
				};
			}
		} {
			common_key.value(script_context, n, z);
		};
	};

	~mouse = { |... args| // TODO: get away from using varargs for ~mouse
		common_mouse.value(*([script_context]++args)); // TODO: get away from using varargs for ~mouse
	};
};
)
