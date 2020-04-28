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

		~engine.new__("LFO", "MultiLFO");
		~engine.new__("Osc", "PulseOsc");
		~engine.new__("SoundOut", "SoundOut");

		~engine.connect__("LFO/Sine", "Osc*PWM");
		~engine.connect__("Osc/Out", "SoundOut*Left");
		~engine.connect__("Osc/Out", "SoundOut*Right");

		~params.add__(
			(
				type: "control",
				id: "osc_range",
				name: "Osc.Range",
				controlspec: ~r.specs__['PulseOsc']['Range'],
				action: { |value| ~engine.set__("Osc.Range", value) }
			)
		);

		lfo_frequency_spec = ~r.specs__['MultiLFO']['Frequency'].copy();
		lfo_frequency_spec.default = 0.2;

		~params.add__(
			(
				type: "control",
				id: "lfo_frequency",
				name: "LFO.Frequency",
				controlspec: lfo_frequency_spec,
				formatter: formatters.round__(0.001),
				action: { |value| ~engine.set__("LFO.Frequency", value) }
			)
		);

		~params.add__(
			(
				type: "control",
				id: "osc_range",
				name: "Osc.Range",
				controlspec: ~r.specs__['PulseOsc']['Range'],
				action: { |value| ~engine.set__("Osc.Range", value) }
			)
		);

		~params.add__(
			(
				type: "control",
				id: "osc_tune",
				name: "Osc.Tune",
				controlspec: ~r.specs__['PulseOsc']['Tune'],
				action: { |value| ~engine.set__("Osc.Tune", value) }
			)
		);

		~params.add__(
			(
				type: "control",
				id: "osc_pulsewidth",
				name: "Osc.PulseWidth",
				controlspec: ~r.specs__['PulseOsc']['PulseWidth'],
				formatter: formatters['percentage'],
				action: { |value| ~engine.set__("Osc.PulseWidth", value) }
			)
		);

		lfo_to_osc_pwm_spec = ~r.specs__['PulseOsc']['PWM'].copy();
		lfo_to_osc_pwm_spec.default = 0.6;

		~params.add__(
			(
				type: "control",
				id: "lfo_to_osc_pwm",
				name: "LFO > Osc.PWM",
				controlspec: lfo_to_osc_pwm_spec,
				formatter: formatters['percentage'],
				action: { |value| ~engine.set__("Osc.PWM", value) }
			)
		);

		~params.bang__()
	};

	~redraw = {
		~screen.clear__();
		~screen.level__(15);
		~screen.move__(1, 10);
		~screen.text__("PWM");
		~screen.move__(1, 30);
		~screen.text__("See params in menu");
		~screen.update__();
	};

	~enc = { |n, delta|
		if (n == 1) {
			~mix.delta("output", delta);
		};
	};
};
)


