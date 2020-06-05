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
	// scriptname: 6_pollvisual
	// v1.1.0 @jah
	var formatters = include_relative.value("lib/formatters.scd");
	var r_specs = include_relative.value("lib/r_specs.scd");

	var val;
	var x;

	~engine.name = 'R';

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

		var screen_y_spec;
		var frequency_visual_spec;
		var poll1;

/*
		var screen_refresh_metro;
		var screen_framerate;
		var screen_dirty = false;
*/

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

		~engine.pollvisual_(1, "Filter=Frequency");

		~params.add_(
			(
				type: "control",
				id: "gate",
				name: "Gate",
				controlspec: r_specs['FreqGate']['Gate'],
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
				controlspec: r_specs['PulseOsc']['Range'],
				action: { |value| ~engine.set_("Osc.Range", value) }
			)
		);

		lfo_frequency_spec = r_specs['MultiLFO']['Frequency'].copy();
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
				controlspec: r_specs['PulseOsc']['PulseWidth'],
				formatter: formatters['percentage'],
				action: { |value| ~engine.set_("Osc.PulseWidth", value) }
			)
		);

		lfo_to_osc_pwm_spec = r_specs['PulseOsc']['PWM'].copy();
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

		env_attack_spec = r_specs['ADSREnv']['Attack'].copy();
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

		env_decay_spec = r_specs['ADSREnv']['Decay'].copy();
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
				controlspec: r_specs['ADSREnv']['Sustain'],
				formatter: formatters['percentage'],
				action: { |value| ~engine.set_("Env.Sustain", value) }
			)
		);

		env_release_spec = r_specs['ADSREnv']['Release'].copy();
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

		filter_frequency_spec = r_specs['MMFilter']['Frequency'].copy();
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

		filter_resonance_spec = r_specs['MMFilter']['Resonance'].copy();
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

		lfo_to_filter_fm_spec = r_specs['LinMixer']['In1'].copy();
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

		env_to_filter_fm_spec = r_specs['LinMixer']['In2'].copy();
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

		~add_output_level_param.value();

		~engine.set_("FilterMod.Out", 1);
		~engine.set_("Filter.FM", 1);

		~params.bang_();

		screen_y_spec = ControlSpec.new(60, 5, 'lin', 1);
		frequency_visual_spec = r_specs['MMFilter']['Frequency'];
		val = 0;
		poll1 = ~poll.set_("poll1") { |value|
			val = screen_y_spec.map(frequency_visual_spec.unmap(value));
			~redraw.value();
		};
		poll1.time_ = 1/25;
		poll1.start_();

/*
	TODO: not used atm
		screen_refresh_metro = ~metro.init_();
		screen_refresh_metro.event = {
			if (screen_dirty) {
				screen_dirty = false;
				~redraw.value();
			};
		};

		screen_framerate = 15;
		screen_refresh_metro.start_(1 / screen_framerate);
*/

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
		case
		{x.isNil} {
			x = 1;
		}
		{x > 128} {
			x = 1;
		}
		{true} {
			x = x + 1;
		};
		~screen.rect_(x, val, 2, 2);
		~screen.fill_();
		~screen.level_(15);
		~screen.move_(1, 10);
		~screen.text_("VISUAL");
		~screen.move_(1, 30);
		// ~screen.text_("See params in menu");
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
