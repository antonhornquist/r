(
var include_relative = { |relative_path|
	var path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ relative_path).standardizePath;
	if (File.exists(path)) {
		var result = this.executeFile(path);
		if (result.isNil) { Error("error importing %".format(path)).throw; } { result }; // TODO: adopt in other places too
	} {
		Error("include_relative: file % does not exist".format(path.quote)).throw;
	};
};

var norns_engine_tester = include_relative.value("../util/norns_engine_tester.scd");
var start_script = norns_engine_tester['start_script'];

start_script.value {
	// scriptname: 1_square
	// v1.1.0 @jah
	var formatters = include_relative.value("lib/formatters.scd");
	var r_specs = include_relative.value("lib/r_specs.scd");

	~engine.name = 'R';

	~init = {
		~engine.new_("Osc", "PulseOsc");
		~engine.new_("Amplifier", "MGain");
		~engine.new_("SoundOut", "SoundOut");

		~engine.connect_("Osc/Out", "Amplifier*In");
		~engine.connect_("Amplifier/Out", "SoundOut*Left");
		~engine.connect_("Amplifier/Out", "SoundOut*Right");

		~add_osc_range_param.value();
		~add_osc_tune_param.value();
		~add_osc_pulsewidth_param.value();
		~add_output_level_param.value();

		~params.bang_();
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
		~screen.text_("SQUARE");
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
			~params.delta_("osc_range", delta);
		}
		{n == 3} {
			~params.delta_("osc_pulsewidth", delta);
		};
	};
};
)


