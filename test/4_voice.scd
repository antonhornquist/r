(
var nel_path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ "../../util/nel.scd").standardizePath;
var nel = this.executeFile(nel_path);
var start_r_engine_script = nel['start_r_engine_script'];

start_r_engine_script.value {
	// scriptname: 1_square
	// v1.1.0 @jah
	var formatters_path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ "formatters.scd").standardizePath;
	var formatters = this.executeFile(formatters_path);

	~init = {
		var lfo_frequency_spec;
		var lfo_to_osc_pwm_spec;
		var env_attack_spec;
		var env_decay_spec;
		var env_release_spec;
		var filter_frequency_spec;
		var filter_resonance_spec;
		var lfo_to_filter_fm_spec;
		var env_to_filter_fm_spec;

		~engine.new_("FreqGate", "FreqGate");
		~engine.new_("LFO", "MultiLFO");
		~engine.new_("Env", "ADSREnv");
		~engine.new_("FilterMod", "LinMixer");
		~engine.new_("Osc", "PulseOsc");
		~engine.new_("Filter", "MMFilter");
		~engine.new_("Amp", "Amp");
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
		~engine.connect_("Amp/Out", "SoundOut*Left");
		~engine.connect_("Amp/Out", "SoundOut*Right");

		~params.add_(
			(
				type: "control",
				id: "gate",
				name: "Gate",
				controlspec: ~r.specs_['FreqGate']['Gate'],
				action: { |value| ~engine.set_("FreqGate.Gate", value) }
			)
		);

		~params.add_(
			(
				type: "control",
				id: "note",
				name: "Note",
				controlspec: \midinote.asSpec,
				action: { |value| ~engine.set_("FreqGate.Frequency", value.midicps) }
			)
		);

		~params.add_(
			(
				type: "control",
				id: "osc_range",
				name: "Osc.Range",
				controlspec: ~r.specs_['PulseOsc']['Range'],
				action: { |value| ~engine.set_("Osc.Range", value) }
			)
		);

		lfo_frequency_spec = ~r.specs_['MultiLFO']['Frequency'].copy();
		lfo_frequency_spec.default = 0.2;

		~params.add_(
			(
				type: "control",
				id: "lfo_frequency",
				name: "LFO.Frequency",
				controlspec: lfo_frequency_spec,
				formatter: formatters.round_(0.001),
				action: { |value| ~engine.set_("LFO.Frequency", value) }
			)
		);

		~params.add_(
			(
				type: "control",
				id: "osc_pulsewidth",
				name: "Osc.PulseWidth",
				controlspec: ~r.specs_['PulseOsc']['PulseWidth'],
				formatter: formatters['percentage'],
				action: { |value| ~engine.set_("Osc.PulseWidth", value) }
			)
		);

		lfo_to_osc_pwm_spec = ~r.specs_['PulseOsc']['PWM'].copy();
		lfo_to_osc_pwm_spec.default = 0.6;

		~params.add_(
			(
				type: "control",
				id: "lfo_to_osc_pwm",
				name: "LFO > Osc.PWM",
				controlspec: lfo_to_osc_pwm_spec,
				formatter: formatters['percentage'],
				action: { |value| ~engine.set_("Osc.PWM", value) }
			)
		);

		env_attack_spec = ~r.specs_['ADSREnv']['Attack'].copy();
		env_attack_spec.default = 1;

		~params.add_(
			(
				type: "control",
				id: "env_attack",
				name: "Env.Attack",
				controlspec: env_attack_spec,
				action: { |value| ~engine.set_("Env.Attack", value) }
			)
		);

		env_decay_spec = ~r.specs_['ADSREnv']['Decay'].copy();
		env_decay_spec.default = 800;

		~params.add_(
			(
				type: "control",
				id: "env_decay",
				name: "Env.Decay",
				controlspec: env_decay_spec,
				action: { |value| ~engine.set_("Env.Decay", value) }
			)
		);

		~params.add_(
			(
				type: "control",
				id: "env_sustain",
				name: "Env.Sustain",
				controlspec: ~r.specs_['ADSREnv']['Sustain'],
				formatter: formatters['percentage'],
				action: { |value| ~engine.set_("Env.Sustain", value) }
			)
		);

		env_release_spec = ~r.specs_['ADSREnv']['Release'].copy();
		env_release_spec.default = 800;

		~params.add_(
			(
				type: "control",
				id: "env_release",
				name: "Env.Release",
				controlspec: env_release_spec,
				action: { |value| ~engine.set_("Env.Release", value) }
			)
		);

		filter_frequency_spec = ~r.specs_['MMFilter']['Frequency'].copy();
		filter_frequency_spec.default = 2000;

		~params.add_(
			(
				type: "control",
				id: "filter_frequency",
				name: "Filter.Frequency",
				controlspec: filter_frequency_spec,
				action: { |value| ~engine.set_("Filter.Frequency", value) }
			)
		);

		filter_resonance_spec = ~r.specs_['MMFilter']['Resonance'].copy();
		filter_resonance_spec.default = 0.4;

		~params.add_(
			(
				type: "control",
				id: "filter_resonance",
				name: "Filter.Resonance",
				controlspec: filter_resonance_spec,
				formatter: formatters['percentage'],
				action: { |value| ~engine.set_("Filter.Resonance", value) }
			)
		);

		lfo_to_filter_fm_spec = ~r.specs_['LinMixer']['In1'].copy();
		lfo_to_filter_fm_spec.default = 0.4;

		~params.add_(
			(
				type: "control",
				id: "lfo_to_filter_fm",
				name: "LFO > Filter.FM",
				controlspec: lfo_to_filter_fm_spec,
				formatter: formatters['percentage'],
				action: { |value| ~engine.set_("FilterMod.In1", value) }
			)
		);

		env_to_filter_fm_spec = ~r.specs_['LinMixer']['In2'].copy();
		env_to_filter_fm_spec.default = 0.3;

		~params.add_(
			(
				type: "control",
				id: "env_to_filter_fm",
				name: "Env > Filter.FM",
				controlspec: env_to_filter_fm_spec,
				formatter: formatters['percentage'],
				action: { |value| ~engine.set_("FilterMod.In2", value) }
			)
		);

		~engine.set_("FilterMod.Out", 1);
		~engine.set_("Filter.FM", 1);

		~params.bang_();

		~midi_device = ~midi.connect_(0);
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

/*
	TODO
	~enc = { |n, delta|
		if (n == 1) {
			~mix.delta_("output", delta);
		};
	};
*/
	~enc = { |n, delta|
		case
		{n == 1} {
			~mix.delta_("output", delta);
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
