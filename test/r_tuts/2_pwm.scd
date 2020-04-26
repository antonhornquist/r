(
var nel_path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ "../../util/nel.scd").standardizePath;
var nel = this.executeFile(nel_path);

var start_script = nel['start_script'];

start_script.value {
	// scriptname: 1_square
	// v1.1.0 @jah
/*
	~engine.name = 'R'

	~r = require 'r/lib/r'
	~formatters = require 'formatters'
*/


	~init = {
		~engine.new__("LFO", "MultiLFO");
		~engine.new__("Osc", "PulseOsc");
		~engine.new__("SoundOut", "SoundOut");

		~engine.connect__("LFO/Sine", "Osc*PWM");
		~engine.connect__("Osc/Out", "SoundOut*Left");
		~engine.connect__("Osc/Out", "SoundOut*Right");

/*
  local lfo_frequency_spec = R.specs.MultiLFO.Frequency:copy()
  lfo_frequency_spec.default = 0.2

  params:add {
    type="control",
    id="lfo_frequency",
    name="LFO.Frequency",
    controlspec=lfo_frequency_spec,
    formatter=Formatters.round(0.001),
    action=function(value) engine.set("LFO.Frequency", value) end
  }

  params:add {
    type="control",
    id="osc_range",
    name="Osc.Range",
    controlspec=R.specs.PulseOsc.Range,
    action=function(value) engine.set("Osc.Range", value) end
  }

  params:add {
    type="control",
    id="osc_tune",
    name="Osc.Tune",
    controlspec=R.specs.PulseOsc.Tune,
    action=function(value) engine.set("Osc.Tune", value) end
  }

  params:add {
    type="control",
    id="osc_pulsewidth",
    name="Osc.PulseWidth",
    controlspec=R.specs.PulseOsc.PulseWidth,
    formatter=Formatters.percentage,
    action=function(value) engine.set("Osc.PulseWidth", value) end
  }

  local lfo_to_osc_pwm_spec = R.specs.PulseOsc.PWM:copy()
  lfo_to_osc_pwm_spec.default = 0.6

  params:add {
    type="control",
    id="lfo_to_osc_pwm",
    name="LFO > Osc.PWM",
    controlspec=lfo_to_osc_pwm_spec,
    formatter=Formatters.percentage,
    action=function(value) engine.set("Osc.PWM", value) end
  }
*/

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
		~screen_text.("PWM");
		~screen_move.(1, 30);
		~screen_text.("See params in menu");
		~screen_update.("See params in menu");
	};

	~enc = { |n, delta|
		if (n == 1) {
			~mix.delta("output", delta);
		};
	};
};
)


