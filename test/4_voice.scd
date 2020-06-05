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
	// scriptname: 4_voice
	// v1.1.0 @jah
	var formatters = include_relative.value("lib/formatters.scd");
	var r_specs = include_relative.value("lib/r_specs.scd");

	~engine.name = 'R';

	~init = {
		~engine.new_("FreqGate", "FreqGate");
		~engine.new_("LFO", "MultiLFO");
		~engine.new_("Env", "ADSREnv");
		~engine.new_("FilterMod", "LinMixer");
		~engine.new_("Osc", "PulseOsc");
		~engine.new_("Filter", "MMFilter");
		~engine.new_("Amp", "Amp");
		~engine.new_("Amplifier", "MGain");
		~engine.new_("SoundOut", "SoundOut");

		~engine.set_("Osc.FM", 1);

		~engine.connect_("FreqGate/Frequency", "Osc*FM");
		~engine.connect_("FreqGate/Gate", "Env*Gate");
		~engine.connect_("LFO/Sine", "Osc*PWM");
		~engine.connect_("LFO/Sine", "FilterMod*In1");
		~engine.connect_("Env/Out", "FilterMod*In2");
		~engine.connect_("Env/Out", "Amp*Lin");
		~engine.connect_("FilterMod/Out", "Filter*FM");

		~engine.connect_("Osc/Out", "Filter*In");
		~engine.connect_("Filter/Lowpass", "Amp*In");
		~engine.connect_("Amp/Out", "Amplifier*In");
		~engine.connect_("Amplifier/Out", "SoundOut*Left");
		~engine.connect_("Amplifier/Out", "SoundOut*Right");

		~add_gate_param.value();
		~add_note_param.value();
		~add_osc_range_param.value();
		~add_lfo_frequency_param.value();
		~add_lfo_to_osc_pwm_param.value();
		~add_filter_frequency_param.value();
		~add_filter_resonance_param.value();
		~add_lfo_to_filter_fm_param.value();
		~add_osc_tune_param.value();
		~add_osc_pulsewidth_param.value();
		~add_env_attack_param.value();
		~add_env_decay_param.value();
		~add_env_sustain_param.value();
		~add_env_release_param.value();
		~add_env_to_filter_fm_param.value();
		~add_output_level_param.value();

		~engine.set_("FilterMod.Out", 1);
		~engine.set_("Filter.FM", 1);

		~params.bang_();

		// TODO: remove (start)
		~midi_device = ~midi.connect_();
		~midi_device.event = { |data|
			case
			{ data.type == 'note_on' } {
				~params.set_("note", data.note);
				~params.set_("gate", 1);
			}
			{ data.type == 'note_off' } {
				~params.set_("gate", 0);
			}
			{ (data.type == 'cc') and: (data.num ==1) } {
				~params.set_raw_("filter_frequency", data.val/127);
			}
			{ (data.type == 'cc') and: (data.num ==2) } {
				~params.set_raw_("filter_resonance", data.val/127);
			}
			{ (data.type == 'cc') and: (data.num ==3) } {
				~params.set_raw_("lfo_frequency", data.val/127);
			};
		};
		// TODO: remove (finish)
	};

	~add_gate_param = {
		~params.add_(
			(
				type: "control",
				id: "gate",
				name: "Gate",
				controlspec: r_specs['FreqGate']['Gate'],
				action: { |value| ~engine.set_("FreqGate.Gate", value) }
			)
		);
	};

	~add_note_param = {
		~params.add_(
			(
				type: "control",
				id: "note",
				name: "Note",
				controlspec: \midinote.asSpec,
				action: { |value| ~engine.set_("FreqGate.Frequency", value.midicps) }
			)
		);
	};

	~add_osc_range_param = {
		~params.add_(
			(
				type: "control",
				id: "osc_range",
				name: "Osc.Range",
				controlspec: r_specs['PulseOsc']['Range'],
				action: { |value| ~engine.set_("Osc.Range", value) }
			)
		);
	};

	~add_lfo_frequency_param = {
		var spec;
		spec = r_specs['MultiLFO']['Frequency'].copy();
		spec.default = 0.2;

		~params.add_(
			(
				type: "control",
				id: "lfo_frequency",
				name: "LFO.Frequency",
				controlspec: spec,
				formatter: formatters.round_(0.001),
				action: { |value| ~engine.set_("LFO.Frequency", value) }
			)
		);
	};

	~add_lfo_to_osc_pwm_param = {
		var spec;
		spec = r_specs['PulseOsc']['PWM'].copy();
		spec.default = 0.6;

		~params.add_(
			(
				type: "control",
				id: "lfo_to_osc_pwm",
				name: "LFO > Osc.PWM",
				controlspec: spec,
				formatter: formatters['percentage'],
				action: { |value| ~engine.set_("Osc.PWM", value) }
			)
		);
	};

	~add_filter_frequency_param = {
		var spec;
		spec = r_specs['MMFilter']['Frequency'].copy();
		spec.default = 2000;

		~params.add_(
			(
				type: "control",
				id: "filter_frequency",
				name: "Filter.Frequency",
				controlspec: spec,
				action: { |value| ~engine.set_("Filter.Frequency", value) }
			)
		);

	};

	~add_filter_resonance_param = {
		var spec;
		spec = r_specs['MMFilter']['Resonance'].copy();
		spec.default = 0.4;

		~params.add_(
			(
				type: "control",
				id: "filter_resonance",
				name: "Filter.Resonance",
				controlspec: spec,
				formatter: formatters['percentage'],
				action: { |value| ~engine.set_("Filter.Resonance", value) }
			)
		);

	};

	~add_lfo_to_filter_fm_param = {
		var spec;
		spec = r_specs['MMFilter']['FM'].copy();
		spec.default = 0.4;

		~params.add_(
			(
				type: "control",
				id: "lfo_to_filter_fm",
				name: "LFO > Filter.FM",
				controlspec: spec,
				formatter: formatters['percentage'],
				action: { |value| ~engine.set_("Filter.FM", value) }
			)
		);

	};

	~add_osc_tune_param = {
		~params.add_(
			(
				type: "control",
				id: "osc_tune",
				name: "Osc.Tune",
				controlspec: r_specs['PulseOsc']['Tune'],
				action: { |value| ~engine.set_("Osc.Tune", value) }
			)
		);
	};

	~add_osc_pulsewidth_param = {
		~params.add_(
			(
				type: "control",
				id: "osc_pulsewidth",
				name: "Osc.PulseWidth",
				controlspec: r_specs['PulseOsc']['PulseWidth'],
				formatter: formatters['percentage'],
				action: { |value| ~engine.set_("Osc.PulseWidth", value) }
			)
		);
	};

	~add_env_attack_param = {
		var spec;
		spec = r_specs['ADSREnv']['Attack'].copy();
		spec.default = 1;

		~params.add_(
			(
				type: "control",
				id: "env_attack",
				name: "Env.Attack",
				controlspec: spec,
				action: { |value| ~engine.set_("Env.Attack", value) }
			)
		);
	};

	~add_env_decay_param = {
		var spec;
		spec = r_specs['ADSREnv']['Decay'].copy();
		spec.default = 800;

		~params.add_(
			(
				type: "control",
				id: "env_decay",
				name: "Env.Decay",
				controlspec: spec,
				action: { |value| ~engine.set_("Env.Decay", value) }
			)
		);
	};

	~add_env_sustain_param = {
		~params.add_(
			(
				type: "control",
				id: "env_sustain",
				name: "Env.Sustain",
				controlspec: r_specs['ADSREnv']['Sustain'],
				formatter: formatters['percentage'],
				action: { |value| ~engine.set_("Env.Sustain", value) }
			)
		);
	};

	~add_env_release_param = {
		var spec;
		spec = r_specs['ADSREnv']['Release'].copy();
		spec.default = 800;

		~params.add_(
			(
				type: "control",
				id: "env_release",
				name: "Env.Release",
				controlspec: spec,
				action: { |value| ~engine.set_("Env.Release", value) }
			)
		);
	};

	~add_env_to_filter_fm_param = {
		var spec;
		spec = r_specs['LinMixer']['In2'].copy();
		spec.default = 0.3;

		~params.add_(
			(
				type: "control",
				id: "env_to_filter_fm",
				name: "Env > Filter.FM",
				controlspec: spec,
				formatter: formatters['percentage'],
				action: { |value| ~engine.set_("FilterMod.In2", value) }
			)
		);
	};

	~add_output_level_param = {
		var spec = r_specs['MGain']['Gain'].copy;
		spec.default = -10;

		~params.add_(
			(
				type: "control",
				id: "output_level",
				name: "Amplifier.Gain",
				controlspec: spec,
				formatter: formatters.round_(0.1),
				action: { |value| ~engine.set_("Amplifier.Gain", value) }
			)
		);
	};

	~redraw = {
		~screen.clear_();
		~screen.level_(15);
		~screen.move_(1, 10);
		~screen.text_("VOICE");
		~screen.move_(1, 30);
		~screen.text_("See params in menu");
		~screen.update_();
	};

	~enc = { |n, delta|
		case
		{n == 1} {
			~params.delta_("output_level", delta);
		}
		{n == 2} {
			~params.delta_("note", delta);
		}
		{n == 3} {
			~params.delta_("filter_frequency", delta);
		};
	};

	~key = { |n, z|
		if (n == 3) {
			case
			{z == 1} {
				~params.set_("gate", 1);
			}
			{z == 0} {
				~params.set_("gate", 0);
			};
		};
	};
};
)
