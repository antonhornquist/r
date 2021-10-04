(
var include_relative = { |relative_path|
	var path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ relative_path).standardizePath;
	if (File.exists(path)) {
		var result = this.executeFile(path);
		if (result.isNil) { Error("error importing %".format(path)).throw; } { result }; // TODO: adopt in other places too
	} {
		Error("include_relative: file % does not exist".format(path.quote)).throw;
	};
};

var norns_engine_tester = include_relative.value("../util/norns_engine_tester.scd");
var start_script = norns_engine_tester['start_script'];

start_script.value {
	// scriptname: moln
	// v1.3.0 @jah
	var moln_spec = include_relative.value('lib/moln_spec.scd');
	var moln_spec_init = moln_spec[\init];
	var moln_spec_note_on = moln_spec[\note_on];
	var moln_spec_note_off = moln_spec[\note_off];

	var formatters = include_relative.value("lib/formatters.scd");

	var common = include_relative.value("lib/common.scd");
	var common_init_script_state = common[\init_script_state];
	var common_redraw = common[\redraw];
	var common_enc = common[\enc];
	var common_key = common[\key];
	var common_mouse = common[\mouse];
	var common_add_params = common[\add_params];
	var common_render_arc = common[\render_arc];
	var common_get_param_id_for_current_page = common[\get_param_id_for_current_page];
	var common_load_settings_and_params = common[\load_settings_and_params];
	var common_calculate_ui_page_label_widths = common[\calculate_ui_page_label_widths];

	var ui_dirty = false;

	var pages = [
		[ (id: "filter_frequency"), (id: "filter_resonance") ],
		[ (id: "osc_a_range"), (id: "osc_b_range") ],
		[ (id: "osc_a_pulsewidth"), (id: "osc_b_pulsewidth") ],
		[ (id: "osc_detune"), (id: "lfo_frequency") ],
		[ (id: "lfo_to_osc_pwm"), (id: "env_to_filter_fm") ],
		[ (id: "env_attack"), (id: "env_decay") ],
		[ (id: "env_sustain"), (id: "env_release") ],
	];

	// arc

	var arc_device;

/*
	TODO
	// grid

	var grid_device;
	var grid_width = Ref.new; // TODO: do not wrap as Ref

	var update_grid_width = {
		if (grid_device.device_.notNil) {
			if (grid_width.dereference != grid_device.cols_) {
				grid_width.set(grid_device.cols_);
			};
		};
	};
*/

	// midi

	var midi_device;

	// event flash

	var show_event_indicator = false;

	var event_flash_frames = 5; // TODO: this ought to be initialized since it's refresh FPS rate affects time
	var event_flash_frame_counter = nil;

	var flash_event = {
		event_flash_frame_counter = event_flash_frames;
	};
	  
	var update_event_indicator = {
		if (event_flash_frame_counter.notNil) {
			event_flash_frame_counter = event_flash_frame_counter - 1;
			case
			{ event_flash_frame_counter == 0 } {
				event_flash_frame_counter = nil;
				show_event_indicator = false;
				ui_dirty = true;
			}
			{ show_event_indicator.not } {
				show_event_indicator = true;
				ui_dirty = true;
			};
		};
	};

	// ui refresh logic
	var update_page_transition = { |state| // TODO: state -> script_state ??
		var current_page = state[\current_page];
		var target_page = state[\target_page];
		var page_trans_div = state[\page_trans_div];
		var new_current_page;
		new_current_page = current_page + page_trans_div;
		state[\page_trans_frames] = state[\page_trans_frames] - 1;
		if (state[\page_trans_frames] == 0) {
			new_current_page = target_page;
			state[\target_page] = nil;
		};
		state[\current_page] = new_current_page;
		ui_dirty = true;
	};

	var refresh_ui = {
		var target_page = script_state[\target_page];
		if (target_page.notNil) {
			update_page_transition.value(script_state);
		};

		update_event_indicator.value();

		// TODO update_grid_width.value();

		if (ui_dirty) {

/*
	TODO
			refresh_grid.value(); // TODO: naming
			grid_device.refresh_();
*/

			common_render_arc.value(~params, script_state, pages, arc_device);
			arc_device.refresh_();

			~redraw.value();

			ui_dirty = false;
		};
	};

	var settings_file = "moln.data";
	var ui_refresh_rate = 35;

	var script_state;

	var init_ui_refresh_metro = {
		var ui_refresh_metro = ~metro.init_();
		ui_refresh_metro.event = refresh_ui;
		ui_refresh_metro.time = 1/ui_refresh_rate;
		ui_refresh_metro.start_();
	};

	var init_ui = {
		arc_device = ~arc.connect_();

		arc_device[\delta] = { |n, delta| // not .delta notation to suppress self argument?
			var d;
			var id;
			var val;

			flash_event.value();

			if (script_state[\fine]) {
				d = delta/5;
			} {
				d = delta;
			};
			id = common_get_param_id_for_current_page.value(pages, script_state, n-1); // TODO: zero-based
			val = ~params.get_raw_(id);
			~params.set_raw_(id, val+(d/500));
			ui_dirty = true;
		};

		midi_device = ~midi.connect_();

		midi_device[\event] = { |data|
			if (engine_ready) {
				var msg = ~midi.to_msg_(data);
				case
				{msg['type'] == 'note_off'} {
					moln_spec_note_off.value(~engine, msg.note);
				}
				{msg['type'] == 'note_on'} {
					moln_spec_note_on.value(~engine, msg.note, msg.vel / 127);

				}
				{msg['type'] == 'cc'} {
					var num = msg['num'];
					var val = msg['val'];
					var rel_cc_delta = if (val > 64, val-128, val);
					[num, val].debug;
					case
					{num == 1} {
						// ~params.delta_( "lfo_frequency", rel_cc_delta);
						common_enc.value(~params, pages, script_state, 2, rel_cc_delta);
					}
					{num == 2} {
						//~params.delta_( "lfo_to_osc_pwm", rel_cc_delta);
						//~params.delta_( "osc_detune", rel_cc_delta);
						common_enc.value(~params, pages, script_state, 3, rel_cc_delta);
					}
					{num == 3} {
						// ~params.delta_( "filter_frequency", rel_cc_delta);
					}
					{num == 4} {
						//~params.delta_( "env_release", rel_cc_delta);
						common_enc.value(~params, pages, script_state, 1, rel_cc_delta);
					}
					{num == 11} {
						case
						{val == 127} {
							common_key.value(pages, ui_refresh_rate, script_state, 2, 1);
						}
						{val == 0} {
							common_key.value(pages, ui_refresh_rate, script_state, 2, 0);
						};
					}
					{num == 12} {
						case
						{val == 127} {
							common_key.value(pages, ui_refresh_rate, script_state, 3, 1);
						}
						{val == 0} {
							common_key.value(pages, ui_refresh_rate, script_state, 3, 0);
						};
					}
					{num == 14} {
						case
						{val == 127} {
							common_key.value(pages, ui_refresh_rate, script_state, 1, 1);
						}
						{val == 0} {
							common_key.value(pages, ui_refresh_rate, script_state, 1, 0);
						};
					}
					;
					ui_dirty = true;
				};
			}
		};

		init_ui_refresh_metro.value();
	};

	var engine_ready = false;

	var start_after_1_second_delay; // TODO: global in lua
	var init_engine_init_delay_metro; // TODO: global in lua


	~engine.name = 'R';

	~init = {
		var spec_instance = moln_spec_init.value(
			(
				engine_global: ~engine,
				visual_buf_size: round(ui_refresh_rate/20)
			)
		);

		common_add_params.value(spec_instance[\param_specs], ~params);

		script_state = common_init_script_state.value();

		common_calculate_ui_page_label_widths.value(~params, ~screen, pages);

		common_load_settings_and_params.value(settings_file, ~params);

		init_ui.value();

		start_after_1_second_delay.value(spec_instance);
	};

	start_after_1_second_delay = {
		init_engine_init_delay_metro.value();
	};

	init_engine_init_delay_metro = {
		var engine_init_delay_metro = ~metro.init_();
		engine_init_delay_metro[\event] = {
			engine_ready = true;

			ui_dirty = true;

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
		common_redraw.value(~params, ~screen, pages, script_state, show_event_indicator);
	};

	~enc = { |n, delta|
		common_enc.value(~params, pages, script_state, n, delta);
	};

	~key = { |n, z|
		if (n == 1) {
			if (z == 1) {
				[60, 63, 67] do: { |note|
					moln_spec_note_on.value(~engine, note, 1);
				};
			} {
				[60, 63, 67] do: { |note|
					moln_spec_note_off.value(~engine, note);
				};
			}
		} {
			common_key.value(pages, ui_refresh_rate, script_state, n, z);
		};
		ui_dirty = true;
	};

	~mouse = { |... args| // TODO: get away from using varargs for ~mouse
		common_mouse.value(*([~params, ~screen, pages, ui_refresh_rate, script_state]++args)); // TODO: get away from using varargs for ~mouse
		ui_dirty = true;
	};
};
)
