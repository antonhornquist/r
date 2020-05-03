(
var include = { |relative_path|
	var path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ relative_path).standardizePath;
	this.executeFile(path);
};

var nel = include.value("../util/nel.scd");
var start_r_engine_script = nel['start_r_engine_script'];

start_r_engine_script.value { |engine|
	// scriptname: 1_square
	// v1.1.0 @jah
	var formatters = include.value("formatters.scd");
	var r_specs = include.value("r_specs.scd");

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


