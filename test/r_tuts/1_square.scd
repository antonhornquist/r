(
var nel_path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ "../../util/nel.scd").standardizePath;
var nel = this.executeFile(nel_path);
var start_script = nel['start_script'];

start_script.value {
	// scriptname: 2_pwm
	// v1.1.0 @jah
	var formatters_path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ "formatters.scd").standardizePath;
	var formatters = this.executeFile(formatters_path);

	~init = {
		~engine.new__("Osc", "PulseOsc");
		~engine.new__("SoundOut", "SoundOut");

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

		~params.bang__();
	};

	~redraw = {
		~screen.clear__();
		~screen.level__(15);
		~screen.move__(1, 10);
		~screen.text__("SQUARE");
		~screen.move__(1, 30);
		~screen.text__("See params in menu");
		~screen.update__();
	};

/*
	~enc = { |n, delta|
		if (n == 1) {
			~mix.delta("output", delta);
		};
	};
*/
	~enc = { |n, delta|
		case
		{n == 1} {
			~mix.delta__("output", delta);
		}
		{n == 2} {
			~params.delta__("osc_range", delta);
		}
		{n == 3} {
			~params.delta__("osc_pulsewidth", delta);
		};
	};
};
)


