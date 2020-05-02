(
var include = { |relative_path|
	var path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ relative_path).standardizePath;
	this.executeFile(path);
};

var nel = include.value("../util/nel.scd");
var start_r_engine_script = nel['start_r_engine_script'];

start_r_engine_script.value {
	// scriptname: 3_filter
	// v1.1.0 @jah
	var formatters = include.value("formatters.scd");
	var r_specs = include.value("r_specs.scd");

	~init = {
		var lfo_frequency_spec;
		var lfo_to_osc_pwm_spec;
		var filter_frequency_spec;
		var filter_resonance_spec;
		var lfo_to_filter_fm_spec;

		~engine.new_("LFO", "MultiLFO");
		~engine.new_("Osc", "PulseOsc");
		~engine.new_("Filter", "MMFilter");
		~engine.new_("SoundOut", "SoundOut");

		~engine.connect_("LFO/Sine", "Osc*PWM");
		~engine.connect_("LFO/Sine", "Filter*FM");

		~engine.connect_("Osc/Out", "Filter*In");

		~engine.connect_("Filter/Lowpass", "SoundOut*Left");
		~engine.connect_("Filter/Lowpass", "SoundOut*Right");

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
				id: "osc_range",
				name: "Osc.Range",
				controlspec: r_specs['PulseOsc']['Range'],
				action: { |value| ~engine.set_("Osc.Range", value) }
			)
		);

		~params.add_(
			(
				type: "control",
				id: "osc_tune",
				name: "Osc.Tune",
				controlspec: r_specs['PulseOsc']['Tune'],
				action: { |value| ~engine.set_("Osc.Tune", value) }
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

		lfo_to_filter_fm_spec = r_specs['MMFilter']['FM'].copy();
		lfo_to_filter_fm_spec.default = 0.4;

		~params.add_(
			(
				type: "control",
				id: "lfo_to_filter_fm",
				name: "LFO > Filter.FM",
				controlspec: lfo_to_filter_fm_spec,
				formatter: formatters['percentage'],
				action: { |value| ~engine.set_("Filter.FM", value) }
			)
		);

		~params.bang_()
	};

	~redraw = {
		~screen.clear_();
		~screen.level_(15);
		~screen.move_(1, 10);
		~screen.text_("FILTER");
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
			~params.delta_("lfo_frequency", delta);
		}
		{n == 3} {
			~params.delta_("lfo_to_filter_fm", delta);
		};
	};
};
)


