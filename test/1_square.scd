(
var nel_path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ "../util/nel.scd").standardizePath;
var nel = this.executeFile(nel_path);
var start_r_engine_script = nel['start_r_engine_script'];

start_r_engine_script.value { |engine|
	// scriptname: 2_pwm
	// v1.1.0 @jah
	var formatters_path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ "formatters.scd").standardizePath;
	var formatters = this.executeFile(formatters_path);

	~init = {
		engine.new_("Osc", "PulseOsc");
		engine.new_("SoundOut", "SoundOut");

		engine.connect_("Osc/Out", "SoundOut*Left");
		engine.connect_("Osc/Out", "SoundOut*Right");

		~params.add_(
			(
				type: "control",
				id: "osc_range",
				name: "Osc.Range",
				controlspec: ~r.specs_['PulseOsc']['Range'],
				action: { |value| engine.set_("Osc.Range", value) }
			)
		);

		~params.add_(
			(
				type: "control",
				id: "osc_tune",
				name: "Osc.Tune",
				controlspec: ~r.specs_['PulseOsc']['Tune'],
				action: { |value| engine.set_("Osc.Tune", value) }
			)
		);

		~params.add_(
			(
				type: "control",
				id: "osc_pulsewidth",
				name: "Osc.PulseWidth",
				controlspec: ~r.specs_['PulseOsc']['PulseWidth'],
				formatter: formatters['percentage'],
				action: { |value| engine.set_("Osc.PulseWidth", value) }
			)
		);

		~params.bang_();
	};

	~redraw = {
		~screen.clear_();
		~screen.level_(15);
		~screen.move_(1, 10);
		~screen.text_("SQUARE");
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
			~params.delta_("osc_range", delta);
		}
		{n == 3} {
			~params.delta_("osc_pulsewidth", delta);
		};
	};
};
)


