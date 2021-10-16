(
var include_relative = { |relative_path|
	var path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ relative_path).standardizePath;
	if (File.exists(path)) {
		var result = this.executeFile(path);
		if (result.isNil) { Error("error importing %".format(path)).throw; } { result };
	} {
		Error("include_relative: file % does not exist".format(path.quote)).throw;
	};
};

var deps_root_relative = ".." +/+ "deps";
var norns_engine_tester = include_relative.value(deps_root_relative +/+ "norns_engine_tester.scd");
var start_script = norns_engine_tester['start_script'];
var script_name = PathName(thisProcess.nowExecutingPath).fileNameWithoutExtension;

start_script.value(script_name++"-original") {
	// scriptname: moln
	// v1.3.0 @jah

	var rrrr = include_relative.value(deps_root_relative +/+ "r.scd");
	var r_specs = rrrr[\specs];
	var r_util = rrrr[\util];
	var r_engine = rrrr[\engine];

	var formatters = include_relative.value(deps_root_relative +/+ "formatters.scd");
	var voice = include_relative.value(deps_root_relative +/+ "voice.scd");
	var voice_new = voice[\voice_new];

	var engine_ready = false;
	var trigging = false;
	var fine = false;
	var lastkeynote;

	var polyphony = 5;
	var note_downs = ();
	var note_slots = ();

	var grid_width;

	var create_modules = {
		r_engine.poly_new_("FreqGate", "FreqGate", polyphony);
		r_engine.poly_new_("LFO", "SineLFO", polyphony);
		r_engine.poly_new_("Env", "ADSREnv", polyphony);
		r_engine.poly_new_("OscA", "PulseOsc", polyphony);
		r_engine.poly_new_("OscB", "PulseOsc", polyphony);
		r_engine.poly_new_("Filter", "LPFilter", polyphony);
		r_engine.poly_new_("Amp", "Amp", polyphony);

		~engine.new_("OutputGain", "SGain");
		~engine.new_("SoundOut", "SoundOut");
	};

	var set_static_module_params = {
		r_engine.poly_set_("OscA.FM", 1, polyphony);
		r_engine.poly_set_("OscB.FM", 1, polyphony);
		r_engine.poly_set_("Filter.AudioLevel", 1, polyphony);
	};

	var connect_modules = {
		r_engine.poly_connect_("FreqGate/Frequency", "OscA*FM", polyphony);
		r_engine.poly_connect_("FreqGate/Frequency", "OscB*FM", polyphony);
		r_engine.poly_connect_("FreqGate/Gate", "Env*Gate", polyphony);
		r_engine.poly_connect_("LFO/Out", "OscA*PWM", polyphony);
		r_engine.poly_connect_("LFO/Out", "OscB*PWM", polyphony);
		r_engine.poly_connect_("Env/Out", "Amp*Lin", polyphony);
		r_engine.poly_connect_("Env/Out", "Filter*FM", polyphony);
		r_engine.poly_connect_("OscA/Out", "Filter*In", polyphony);
		r_engine.poly_connect_("OscB/Out", "Filter*In", polyphony);
		r_engine.poly_connect_("Filter/Out", "Amp*In", polyphony);
		
		polyphony.do { |i|
			var voicenum = i + 1;
			~engine.connect_("Amp"++voicenum++"/Out", "OutputGain*Left");
			~engine.connect_("Amp"++voicenum++"/Out", "OutputGain*Right");
		};
		~engine.connect_("OutputGain/Left", "SoundOut*Left");
		~engine.connect_("OutputGain/Right", "SoundOut*Right");
	};

	var create_macros = {
		~engine.newmacro_("osc_a_range", r_util.poly_expand_("OscA.Range", polyphony));
		~engine.newmacro_("osc_a_pulsewidth", r_util.poly_expand_("OscA.PulseWidth", polyphony));
		~engine.newmacro_("osc_b_range", r_util.poly_expand_("OscB.Range", polyphony));
		~engine.newmacro_("osc_b_pulsewidth", r_util.poly_expand_("OscB.PulseWidth", polyphony));
		~engine.newmacro_("osc_a_detune", r_util.poly_expand_("OscA.Tune", polyphony));
		~engine.newmacro_("osc_b_detune", r_util.poly_expand_("OscB.Tune", polyphony));
		~engine.newmacro_("lfo_frequency", r_util.poly_expand_("LFO.Frequency", polyphony));
		~engine.newmacro_("osc_a_pwm", r_util.poly_expand_("OscA.PWM", polyphony));
		~engine.newmacro_("osc_b_pwm", r_util.poly_expand_("OscB.PWM", polyphony));
		~engine.newmacro_("filter_frequency", r_util.poly_expand_("Filter.Frequency", polyphony));
		~engine.newmacro_("filter_resonance", r_util.poly_expand_("Filter.Resonance", polyphony));
		~engine.newmacro_("env_to_filter_fm", r_util.poly_expand_("Filter.FM", polyphony));
		~engine.newmacro_("env_attack", r_util.poly_expand_("Env.Attack", polyphony));
		~engine.newmacro_("env_decay", r_util.poly_expand_("Env.Decay", polyphony));
		~engine.newmacro_("env_sustain", r_util.poly_expand_("Env.Sustain", polyphony));
		~engine.newmacro_("env_release", r_util.poly_expand_("Env.Release", polyphony));
	};

	var init_osc_a_range_param = {
		~params.add_(
			(
				type: "control",
				id: "osc_a_range",
				name: "Osc A Range",
				controlspec: r_specs[\PulseOsc][\Range],
				formatter: formatters[\round].value(1),
				action: { |value|
					~engine.macroset_("osc_a_range", value);
				}
			)
		);
	};

	var init_osc_a_pulsewidth_param = {
		var spec = r_specs[\PulseOsc][\PulseWidth].copy();
		spec.default = 0.88;

		~params.add_(
			(
				type: "control",
				id: "osc_a_pulsewidth",
				name: "Osc A Pulse Width",
				controlspec: spec,
				formatter: formatters[\percentage],
				action: { |value|
					~engine.macroset_("osc_a_pulsewidth", value);
				}
			)
		);
	};

	var init_osc_b_range_param = {
		~params.add_(
			(
				type: "control",
				id: "osc_b_range",
				name: "Osc B Range",
				controlspec: r_specs[\PulseOsc][\Range],
				formatter: formatters[\round].value(1),
				action: { |value|
					~engine.macroset_("osc_b_range", value);
				}
			)
		);
	};

	var init_osc_b_pulsewidth_param = {
		var spec = r_specs[\PulseOsc][\PulseWidth].copy();
		spec.default = 0.88;

		~params.add_(
			(
				type: "control",
				id: "osc_b_pulsewidth",
				name: "Osc B Pulse Width",
				controlspec: spec,
				formatter: formatters[\percentage],
				action: { |value|
					~engine.macroset_("osc_b_pulsewidth", value);
				}
			)
		);
	};

	var init_osc_detune_param = {
		var spec = \unipolar.asSpec.copy();
		spec.default = 0.36;

		~params.add_(
			(
				type: "control",
				id: "osc_detune",
				name: "Detune",
				controlspec: spec,
				formatter: formatters[\percentage],
				action: { |value|
					~engine.macroset_("osc_a_detune", -1 * value * 20);
					~engine.macroset_("osc_b_detune", value * 20);
				}
			)
		);
	};

	var init_lfo_frequency_param = {
		var spec = r_specs[\MultiLFO][\Frequency].copy();
		spec.default = 0.125;

		~params.add_(
			(
				type: "control",
				id: "lfo_frequency",
				name: "PWM Rate",
				controlspec: spec,
				formatter: formatters[\round].value(0.001),
				action: { |value|
					~engine.macroset_("lfo_frequency", value);
				}
			)
		);
	};

	var init_lfo_to_osc_pwm_param = {
		var spec = \unipolar.asSpec.copy();
		spec.default = 0.46;

		~params.add_(
			(
				type: "control",
				id: "lfo_to_osc_pwm",
				name: "PWM Depth",
				controlspec: spec,
				formatter: formatters[\percentage],
				action: { |value|
					~engine.macroset_("osc_a_pwm", value*0.76);
					~engine.macroset_("osc_b_pwm", value*0.56);
				}
			)
		);
	};

	var init_filter_frequency_param = {
		var spec = r_specs[\LPFilter][\Frequency].copy();
		spec.maxval = 8000;
		spec.minval = 10;
		spec.default = 500;

		~params.add_(
			(
				type: "control",
				id: "filter_frequency",
				name: "Filter Frequency",
				controlspec: spec,
				formatter: formatters[\adaptive_freq],
				action: { |value|
					~engine.macroset_("filter_frequency", value);
				}
			)
		);
	};

	var init_filter_resonance_param = {
		var spec = r_specs[\LPFilter][\Resonance].copy();
		spec.default = 0.2;

		~params.add_(
			(
				type: "control",
				id: "filter_resonance",
				name: "Filter Resonance",
				controlspec: spec,
				formatter: formatters[\percentage],
				action: { |value|
					~engine.macroset_("filter_resonance", value);
				}
			)
		);
	};

	var init_env_to_filter_fm_param = {
		var spec = r_specs[\LPFilter][\FM].copy();
		spec.default = 0.35;

		~params.add_(
			(
				type: "control",
				id: "env_to_filter_fm",
				name: "Env > Filter Frequency",
				controlspec: spec,
				formatter: formatters[\percentage],
				action: { |value|
					~engine.macroset_("env_to_filter_fm", value);
				}
			)
		);
	};

	var init_env_attack_param = {
		var spec = r_specs[\ADSREnv][\Attack].copy();
		spec.default = 1;

		~params.add_(
			(
				type: "control",
				id: "env_attack",
				name: "Env Attack",
				controlspec: spec,
				formatter: formatters[\adaptive_time],
				action: { |value|
					~engine.macroset_("env_attack", value);
				}
			)
		);
	};

	var init_env_decay_param = {
		var spec = r_specs[\ADSREnv][\Decay].copy();
		spec.default = 200;

		~params.add_(
			(
				type: "control",
				id: "env_decay",
				name: "Env Decay",
				controlspec: spec,
				formatter: formatters[\adaptive_time],
				action: { |value|
					~engine.macroset_("env_decay", value);
				}
			)
		);
	};

	var init_env_sustain_param = {
		var spec = r_specs[\ADSREnv][\Sustain].copy();
		spec.default = 0.5;

		~params.add_(
			(
				type: "control",
				id: "env_sustain",
				name: "Env Sustain",
				controlspec: spec,
				formatter: formatters[\percentage],
				action: { |value|
					~engine.macroset_("env_sustain", value);
				}
			)
		);
	};

	var init_env_release_param = {
		var spec = r_specs[\ADSREnv][\Release].copy();
		spec.default = 500;

		~params.add_(
			(
				type: "control",
				id: "env_release",
				name: "Env Release",
				controlspec: spec,
				formatter: formatters[\adaptive_time],
				action: { |value|
					~engine.macroset_("env_release", value);
				}
			)
		);
	};

	var init_moln_output_level_param = {
		var spec = r_specs['SGain']['Gain'].copy;
		spec.default = -10;

		~params.add_(
			(
				type: "control",
				id: "moln_output_level",
				name: "Output Level",
				controlspec: spec,
				formatter: formatters.round_(0.1),
				action: { |value|
					~engine.set_("OutputGain.Gain", value);
				}
			)
		);
	};

	var init_params = {
		init_filter_frequency_param.value();
		init_filter_resonance_param.value();
		init_osc_a_range_param.value();
		init_osc_b_range_param.value();
		init_osc_a_pulsewidth_param.value();
		init_osc_b_pulsewidth_param.value();
		init_osc_detune_param.value();
		init_lfo_frequency_param.value();
		init_lfo_to_osc_pwm_param.value();
		init_env_to_filter_fm_param.value();
		init_env_attack_param.value();
		init_env_decay_param.value();
		init_env_sustain_param.value();
		init_env_release_param.value();
		init_moln_output_level_param.value();
	};

	var release_voice = { |voicenum|
		~engine.bulkset_("FreqGate"++voicenum++".Gate 0");
	};

	var trig_voice = { |voicenum, note|
		~engine.bulkset_("FreqGate"++voicenum++".Gate 1 FreqGate"++voicenum++".Frequency "++note.midicps);
	};

	var note_on = { |note, velocity|
		if (note_slots[note].isNil) {
			var slot = ~voice_allocator.get__();
			var voicenum = slot[\id__]; // TODO: + 1 ---- 0 or 1 based?
			trig_voice.value(voicenum, note);
			slot[\on_release__] = {
				release_voice.value(voicenum);
				note_slots[note] = nil;
			};
			note_slots[note] = slot;
			note_downs[voicenum] = note;
		};
	};

	var note_off = { |note|
		var slot = note_slots[note];
		if (slot.notNil) {
			~voice_allocator.release__(slot);
			note_downs[slot[\id]] = nil;
		};
	};

	var gridkey_to_note = { |x, y, grid_width|
		if (grid_width == 16) {
			(x * 8) + y;
		} {
			((4 + x) * 8) + y;
		};
	};

	var note_to_gridkey = { |note, grid_width|
		if (grid_width == 16) {
			[floor((note - 1) / 8), ((note - 1) % 8) + 1]
		} {
			[floor((note - 1) / 8) - 4, ((note - 1) % 8) + 1]
		};
	};

	var init_engine_init_delay_metro = {
		var engine_init_delay_metro = ~metro.init_();
		engine_init_delay_metro[\event] = {
			engine_ready = true;

			ui_dirty = true;

			engine_init_delay_metro.stop_();
		};
		engine_init_delay_metro.time = 1;
		engine_init_delay_metro.start_();
	};

	var init_60_fps_ui_refresh_metro = {
		var ui_refresh_metro = ~metro.init_();
		ui_refresh_metro.event = refresh_ui;
		ui_refresh_metro.time = 1/60;
		ui_refresh_metro.start_();
	};

	var ui_dirty = false;

	var show_event_indicator = false;

	var event_flash_frames = 5;
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

	var update_grid_width = {
		if (~grid_device.device_.notNil) {
			if (grid_width != ~grid_device.cols_) {
				grid_width = ~grid_device.cols_;
			};
		};
	};

	var refresh_arc = {
		~arc_device.all_(0);
		~arc_device.led_(1, round(~params.get_raw_("filter_frequency")*64), 15); // TODO: bug
		~arc_device.led_(2, round(~params.get_raw_("filter_resonance")*64), 15); // TODO: bug
		~arc_device.refresh_();
	};

	var refresh_grid = {
		~grid_device.all_(0);
		polyphony.do { |voicenum|
			var note = note_downs[voicenum];
			if (note.notNil) {
				var x, y;
				# x, y = note_to_gridkey.value(note, grid_width);
				~grid_device.led_(x, y, 15);
			}
		};
		~grid_device.refresh_();
	};

	var refresh_ui = {
		update_event_indicator.value();
    	update_grid_width.value();

		if (ui_dirty) {
			~redraw.value();
			refresh_arc.value();
			refresh_grid.value();
			ui_dirty = false;
		};
	};

	var init_arc = {
		~arc_device = ~arc.connect_();
		~arc_device[\delta] = { |n, delta| // not .delta notation to suppress self argument?
			var d;

			flash_event.value();

			if (fine) {
				d = delta/5;
			} {
				d = delta;
			};

			case
			{n == 1} {
				var val = ~params.get_raw_("filter_frequency");
				~params.set_raw_("filter_frequency", val+(d/500));
			}
			{n == 2} {
				var val = ~params.get_raw_("filter_resonance");
				~params.set_raw_("filter_resonance", val+(d/500));
			};

			ui_dirty = true;
		};
	};

	var init_grid = {
		~grid_device = ~grid.connect_();
		~grid_device[\key] = { |x, y, state|
			if (engine_ready) {
				var note = gridkey_to_note.value(x, y, grid_width);
				if (state == 1) {
					note_on.value(note, 5);
				} {
					note_off.value(note);
				};
				ui_dirty = true;
			};
			flash_event.value();
		};
	};

	var init_midi = {
		var midi_device = ~midi.connect_();
		midi_device[\event] = { |data|
			if (engine_ready) {
				var msg = ~midi.to_msg_(data);
				case
				{msg['type'] == 'note_off'} {
					note_off.value(msg.note);
				}
				{msg['type'] == 'note_on'} {
					note_on.value(msg.note, msg.vel / 127);

				}
				{msg['type'] == 'cc'} {
					var num = msg['num'];
					var val = msg['val'];
					var rel_cc_delta = if (val > 64, val-128, val);
					[num, val].debug;
					case
					{num == 1} {
						~params.delta_( "lfo_frequency", rel_cc_delta);
					}
					{num == 2} {
						//~params.delta_( "lfo_to_osc_pwm", rel_cc_delta);
						~params.delta_( "osc_detune", rel_cc_delta);
					}
					{num == 3} {
						~params.delta_( "filter_frequency", rel_cc_delta);
					}
					{num == 4} {
						~params.delta_( "env_release", rel_cc_delta);
					}
					{num == 11} {
						case
						{val == 127} {
							~key.value(2, 1);
						}
						{val == 0} {
							~key.value(2, 0);
						};
					}
					{num == 12} {
						case
						{val == 127} {
							~key.value(3, 1);
						}
						{val == 0} {
							~key.value(3, 0);
						};
					}
					{num == 14} {
						case
						{val == 127} {
							~key.value(1, 1);
						}
						{val == 0} {
							~key.value(1, 0);
						};
					}
					;
					ui_dirty = true;
				};
			}
		};
	};

	var init_ui = {
		init_arc.value();
		init_grid.value();
		init_midi.value();
		init_60_fps_ui_refresh_metro.value();
		init_engine_init_delay_metro.value();
	};

	~engine.name = 'R';

	~init = {
		~voice_allocator = voice_new.value(polyphony);

		create_modules.value();
		set_static_module_params.value();
		connect_modules.value();
		create_macros.value();

		init_params.value();
		init_ui.value();

		~params.read_();
		~params.bang_();
	};

	~cleanup = {
		~params.write_();
	};

	~redraw = {
		var hi_level = 15;
		var lo_level = 4;

		var enc1_x = 1;
		var enc1_y = 12;

		var enc2_x = 10;
		var enc2_y = 32;

		var enc3_x = enc2_x + 65;
		var enc3_y = enc2_y;

		var key2_x = 1;
		var key2_y = 63;

		var key3_x = key2_x+65;
		var key3_y = key2_y;

		var redraw_enc1_widget = {
			~screen.move_(enc1_x, enc1_y);
			~screen.level_(lo_level);
			~screen.text_("LEVEL");
			~screen.move_(enc1_x+45, enc1_y);
			~screen.level_(hi_level);
			~screen.text_(round(~params.get_raw_("moln_output_level")*100).asInteger.asString);
		};

		var redraw_event_flash_widget = {
			~screen.level_(lo_level);
			~screen.rect_(122, enc1_y-7, 5, 5);
			~screen.fill_();
		};

		var redraw_enc2_widget = {
			~screen.move_(enc2_x, enc2_y);
			~screen.level_(lo_level);
			~screen.text_("FREQ");
			~screen.move_(enc2_x, enc2_y+12);
			~screen.level_(hi_level);
			~screen.text_(~params.get_("filter_frequency"));
		};

		var redraw_enc3_widget = {
			~screen.move_(enc3_x, enc3_y);
			~screen.level_(lo_level);
			~screen.text_("RES");
			~screen.move_(enc3_x, enc3_y+12);
			~screen.level_(hi_level);
			~screen.text_(~params.get_("filter_resonance"));
		};

		var redraw_key2_widget = {
			~screen.move_(key2_x, key2_y);
			if (fine) {
				~screen.level_(hi_level);
				~screen.text_("FINE");
			} {
				~screen.level_(lo_level);
				~screen.text_("COARSE");
			};
		};

		var redraw_key3_widget = {
			~screen.move_(key3_x, key3_y);
			if (engine_ready) {
				if (trigging) {
					~screen.level_(hi_level);
				} {
					~screen.level_(lo_level);
				};
				~screen.text_("TRIG");
			};
		};

		~screen.font_size_(16);
		~screen.clear_();

		redraw_enc1_widget.value();

		if (show_event_indicator) {
			redraw_event_flash_widget.value();
		};

		redraw_enc2_widget.value();
		redraw_enc3_widget.value();
		redraw_key2_widget.value();
		redraw_key3_widget.value();

		~screen.update_();
	};

	~enc = { |n, delta|
		var d;
		if (fine) {
			d = delta/5;
		} {
			d = delta;
		};
		case
		{ n == 1 } {
			~params.delta_("main_level", d);
			ui_dirty = true;
		}
		{ n == 2 } {
			~params.delta_("filter_frequency", d);
		}
		{ n == 3 } {
			~params.delta_("filter_resonance", d);
		}
	};

	~key = { |n, z|
		case
		{ n == 2 } {
			if (z == 1) {
				fine = true;
			} {
				fine = false;
			};
			ui_dirty = true;
		}
		{ n == 3 } {
			if (engine_ready) {
				if (z == 1) {
					lastkeynote = 60.rand + 20;
					note_on.value(lastkeynote, 100);
					trigging = true;
					ui_dirty = true;
				} {
					if (lastkeynote.notNil) {
						note_off.value(lastkeynote, 100);
						trigging = false;
						ui_dirty = true;
					};
				};
			}
		};
	};
};
)
