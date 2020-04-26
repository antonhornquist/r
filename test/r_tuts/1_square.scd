(
var nel_path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ "../../util/nel.scd").standardizePath;
var nel = this.executeFile(nel_path);

var start_script = nel['start_script'];

start_script.value {
	// scriptname: 2_pwm
	// v1.1.0 @jah
/*
	~engine.name = 'R'

	~r = require 'r/lib/r'
	~formatters = require 'formatters'
*/


	~init = {
		~engine.new__("Osc", "PulseOsc");
		~engine.new__("SoundOut", "SoundOut");

		~engine.connect__("Osc/Out", "SoundOut*Left");
		~engine.connect__("Osc/Out", "SoundOut*Right");

		~params[\add].(
			(
				type: "control",
				id: "osc_range",
				name: "Osc.Range",
//				controlspec: ~r.specs__[\PulseOsc][\Range],
//				action: { |value| ~engine.set__("Osc.Range", value) }
			)
		);

		~params[\add].(
			(
				type: "control",
				id: "osc_tune",
				name: "Osc.Tune",
//				controlspec: ~r.specs__[\PulseOsc][\Tune],
//				action: { |value| ~engine.set__("Osc.Tune", value) }
			)
		);

		~params[\add].(
			(
				type: "control",
				id: "osc_pulsewidth",
				name: "Osc.PulseWidth",
//				controlspec: ~r.specs__[\PulseOsc][\PulseWidth],
//				formatter: ~formatters.percentage__,
//				action: { |value| ~engine.set__("Osc.PulseWidth", value) }
			)
		);

		~params[\bang].()
	};

	~redraw = {
		~screen_clear.();
		~screen_level.(15);
		~screen_move.(1, 10);
		~screen_text.("SQUARE");
		~screen_move.(1, 30);
		~screen_text.("See params in menu");
		~screen_update.("See params in menu");
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
			~mix.delta("output", delta);
		}
		{n == 2} {
			~params.delta("osc_range", delta);
		}
		{n == 3} {
			~params.delta("osc_pulsewidth", delta);
		};
	};
};
)


