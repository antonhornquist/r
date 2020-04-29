(
var nel_path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ "../../util/nel.scd").standardizePath;
var nel = this.executeFile(nel_path);
var start_script = nel['start_script'];

start_script.value {
	// scriptname: 1_square
	// v1.1.0 @jah
	var formatters_path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ "formatters.scd").standardizePath;
	var formatters = this.executeFile(formatters_path);

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
				id: "osc_range",
				name: "Osc.Range",
				controlspec: ~r.specs_['PulseOsc']['Range'],
				action: { |value| ~engine.set_("Osc.Range", value) }
			)
		);

		~params.add_(
			(
				type: "control",
				id: "osc_tune",
				name: "Osc.Tune",
				controlspec: ~r.specs_['PulseOsc']['Tune'],
				action: { |value| ~engine.set_("Osc.Tune", value) }
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

		lfo_to_filter_fm_spec = ~r.specs_['MMFilter']['FM'].copy();
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

	~enc = { |n, delta|
		if (n == 1) {
			~mix.delta_("output", delta);
		};
	};
};
)


