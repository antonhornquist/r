(
var include_relative = { |relative_path|
	var path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ relative_path).standardizePath;
	this.executeFile(path);
};

var nel = include_relative.value("../util/nel.scd");
var start_r_engine_script = nel['start_r_engine_script'];

start_r_engine_script.value { |engine|
	// scriptname: 2_pwm
	// v1.1.0 @jah
	var formatters = include_relative.value("formatters.scd");
	var r_specs = include_relative.value("r_specs.scd");

	~init = {
		var lfo_frequency_spec;
		var lfo_to_osc_pwm_spec;

		engine.new_("LFO", "MultiLFO");
		engine.new_("Osc", "PulseOsc");
		engine.new_("SoundOut", "SoundOut");

		engine.connect_("LFO/Sine", "Osc*PWM");
		engine.connect_("Osc/Out", "SoundOut*Left");
		engine.connect_("Osc/Out", "SoundOut*Right");

		~params.add_(
			(
				type: "control",
				id: "osc_range",
				name: "Osc.Range",
				controlspec: r_specs['PulseOsc']['Range'],
				action: { |value| engine.set_("Osc.Range", value) }
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
				action: { |value| engine.set_("LFO.Frequency", value) }
			)
		);

		~params.add_(
			(
				type: "control",
				id: "osc_range",
				name: "Osc.Range",
				controlspec: r_specs['PulseOsc']['Range'],
				action: { |value| engine.set_("Osc.Range", value) }
			)
		);

		~params.add_(
			(
				type: "control",
				id: "osc_tune",
				name: "Osc.Tune",
				controlspec: r_specs['PulseOsc']['Tune'],
				action: { |value| engine.set_("Osc.Tune", value) }
			)
		);

		~params.add_(
			(
				type: "control",
				id: "osc_pulsewidth",
				name: "Osc.PulseWidth",
				controlspec: r_specs['PulseOsc']['PulseWidth'],
				formatter: formatters['percentage'],
				action: { |value| engine.set_("Osc.PulseWidth", value) }
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
				action: { |value| engine.set_("Osc.PWM", value) }
			)
		);

		~params.bang_()
	};

	~redraw = {
		~screen.clear_();
		~screen.level_(15);
		~screen.move_(1, 10);
		~screen.text_("PWM");
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
			~params.delta_("lfo_to_osc_pwm", delta);
		};
	};
};
)


