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
	// scriptname: bob
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
	var fps = 35;

	var engine_ready = false;

	var r_polls, visual_values, r_params;
	var ui;

	var start_after_1_second_delay; // TODO: global in lua
	var init_engine_init_delay_metro; // TODO: global in lua

	~engine.name = 'R';

	~init = {
		# r_polls, visual_values, r_params = r_moln_init.value(round(fps/20));

		ui = (
			arc: ( device: ~arc.connect_() ),
			midi: (
				device: ~midi.connect_(),
				on_event: { |data|
					if (engine_ready) {
						var msg = ~midi.to_msg_(data);
						case
						{msg['type'] == 'note_off'} {
							r_moln_note_off.value(msg.note);
						}
						{msg['type'] == 'note_on'} {
							r_moln_note_on.value(msg.note, msg.vel / 127);

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
				[
					(
						label: "FREQ",
						id: "filter_frequency",
						formatter: formatters[\adaptive_freq]
					),
					(
						label: "RES",
						id: "filter_resonance",
						formatter: formatters[\percentage]
					),
				],
				[
					(
						label: "A.RNG",
						id: "osc_a_range",
						formatter: formatters[\range],
					),
					(
						label: "B.RNG",
						id: "osc_b_range",
						formatter: formatters[\range]
					),
				],
				[
					(
						label: "A.PW",
						id: "osc_a_pulsewidth",
						formatter: formatters[\percentage],
					),
					(
						label: "B.PW",
						id: "osc_b_pulsewidth",
						formatter: formatters[\percentage],
					),
				],
				[
					(
						label: "DETUN",
						id: "osc_detune",
						formatter: formatters[\percentage],
					),
					(
						label: "LFO",
						id: "lfo_frequency",
						formatter: formatters[\adaptive_freq],
					),
				],
				[
					(
						label: "PWM",
						id: "lfo_to_osc_pwm",
						formatter: formatters[\percentage],
					),
					(
						label: "E>FIL",
						id: "env_to_filter_fm",
						formatter: formatters[\percentage],
					),
				],
				[
					(
						label: "E.ATK",
						id: "env_attack",
						formatter: formatters[\adaptive_time],
					),
					(
						label: "E.DEC",
						id: "env_decay",
						formatter: formatters[\adaptive_time],
					),
				],
				[
					(
						label: "E.SUS",
						id: "env_sustain",
						formatter: formatters[\percentage],
					),
					(
						label: "E.REL",
						id: "env_release",
						formatter: formatters[\adaptive_time],
					),
				],
			]
		);

		start_after_1_second_delay.value;
	};

	start_after_1_second_delay = {
		init_engine_init_delay_metro.value();
		common_init.value(r_polls, r_params, ui, settings_file, fps);
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

	~cleanup = {
		common_cleanup.value(settings_file);
	};

	~redraw = {
		common_redraw.value();
	};

	~enc = { |n, delta|
		common_enc.value(n, delta);
	};

	~key = { |n, z|
		common_key.value(n, z);
	};

	~mouse = { |... args|
		common_mouse.value(*args);
	};
};
)
