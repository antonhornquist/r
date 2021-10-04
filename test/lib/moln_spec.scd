(
var include_relative = { |relative_path|
	var path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ relative_path).standardizePath;
	if (File.exists(path)) {
		this.executeFile(path);
	} {
		Error("include_relative: file % does not exist".format(path.quote)).throw;
	};
};

// TODO: refactor to separate file (start)
var r_specs = include_relative.value("r_specs.scd");
var r_util = (
	// utility function to expand a moduleparam ref to #polyphony ones suffixed with 1..polyphony
	poly_expand_: { |self, moduleparam, polyphony|
		var module, param;
		# module, param = r_util.split_ref_(moduleparam);

		polyphony.collect { |i|
			var voicenum = i + 1;
    		r_util.param_voice_ref_(module, param, voicenum);
		}.join(" ");
	},
	param_voice_ref_: { |self, module, param, voicenum|
		module ++ voicenum ++ "." ++ param
	},
	split_ref_: { |self, ref|
		ref = ref.asString;

		case
		{ref.includes($/)} {
			ref.split($/);
		}
		{ref.includes($*)} {
			ref.split($*);
		}
		{ref.includes($.)} {
			ref.split($.);
		}
	}
);
var r_engine = (
	// utility function to create multiple modules suffixed 1..polyphony
	poly_new_: { |self, name, kind, polyphony|
		kind = kind.asSymbol;
		if (r_specs[kind].notNil) {
			polyphony.do { |i|
				var voicenum = i + 1;
				~engine.new_(name++voicenum, kind); // TODO
			};
		} {
			Error(kind.asString ++ " not a valid module type").throw;
		};
	},
	// utility function to set param of multiple modules suffixed 1..polyphony
	poly_set_: { |self, ref, value, polyphony|
		var module, param;
		# module, param = r_util.split_ref_(ref);
		polyphony.do { |i|
			var voicenum = i + 1;
			~engine.set_(r_util.param_voice_ref_(module, param, voicenum), value); // TODO
		};
	},
	// utility function to connect modules suffixed with 1..polyphony
	poly_connect_: { |self, output, input, polyphony|
		var sourcemodule, outputref;
		var destmodule, inputref;
		# sourcemodule, outputref = r_util.split_ref_(output);
		# destmodule, inputref = r_util.split_ref_(input);
		polyphony.do { |i|
			var voicenum = i + 1;
			~engine.connect_(sourcemodule++voicenum++"/"++outputref, destmodule++voicenum++"*"++inputref); // TODO
		};
	},
);
// TODO: refactor to separate file (fin)

var formatters = include_relative.value("formatters.scd");
var custom_formatters = include_relative.value("formatters.scd"); // TODO: ... this
var voice = include_relative.value("voice.scd");
var voice_new = voice[\voice_new];

var polyphony = 5;
var note_downs = ();
var note_slots = ();
var voice_allocator;

var init = { |config|
	var engine_global = config[\engine_global] ?? { Error("engine global is required").throw }; // TODO: make this more declarative: do not invoke engine global here, only send back metadata

	// TODO: visuals not used
/*
	var visual_buf_size = config[\visual_buf_size] ?? { Error("visual_buf_size is required").throw };
	var visual_value_bufs = create_visual_values_bufs.value(visual_buf_size);
*/

	voice_allocator = voice_new.value(polyphony);
	init_r_modules.value(engine_global);

	(
		param_specs: get_param_specs.value(engine_global),
/*
	TODO
		poll_specs: get_poll_specs.value(visual_value_bufs),
		visual_values: visual_value_bufs // TODO: rename key to visual_value_bufs too
*/
	)
};

var init_r_modules = { |engine_global|
	create_modules.value(engine_global);
	set_static_module_params.value(engine_global);
	connect_modules.value(engine_global);
	create_macros.value(engine_global);
};

var create_modules = { |engine_global|
	r_engine.poly_new_("FreqGate", "FreqGate", polyphony);
	r_engine.poly_new_("LFO", "SineLFO", polyphony);
	r_engine.poly_new_("Env", "ADSREnv", polyphony);
	r_engine.poly_new_("OscA", "PulseOsc", polyphony);
	r_engine.poly_new_("OscB", "PulseOsc", polyphony);
	r_engine.poly_new_("Filter", "LPFilter", polyphony);
	r_engine.poly_new_("Amp", "Amp", polyphony);

	engine_global.new_("Amplifier", "SGain");
	engine_global.new_("SoundOut", "SoundOut")
};

var set_static_module_params = { |engine_global|
	r_engine.poly_set_("OscA.FM", 1, polyphony);
	r_engine.poly_set_("OscB.FM", 1, polyphony);
	r_engine.poly_set_("Filter.AudioLevel", 1, polyphony);
};

var connect_modules = { |engine_global|
	r_engine.poly_connect_("FreqGate/Frequency", "OscA*FM", polyphony);
	r_engine.poly_connect_("FreqGate/Frequency", "OscB*FM", polyphony);
	r_engine.poly_connect_("FreqGate/Gate", "Env*Gate", polyphony);
	r_engine.poly_connect_("LFO/Out", "OscA*PWM", polyphony);
	r_engine.poly_connect_("LFO/Out", "OscB*PWM", polyphony);
	r_engine.poly_connect_("Env/Out", "Amp*Lin", polyphony);
	r_engine.poly_connect_("Env/Out", "Filter*FM", polyphony);
	r_engine.poly_connect_("OscA/Out", "Filter*In", polyphony);
	r_engine.poly_connect_("OscB/Out", "Filter*In", polyphony);
	r_engine.poly_connect_("Filter/Out", "Amp*In", polyphony);
	
	polyphony.do { |i|
		var voicenum = i + 1;
		engine_global.connect_("Amp"++voicenum++"/Out", "Amplifier*Left");
		engine_global.connect_("Amp"++voicenum++"/Out", "Amplifier*Right");
	};
	engine_global.connect_("Amplifier/Left", "SoundOut*Left");
	engine_global.connect_("Amplifier/Right", "SoundOut*Right");
};

var create_macros = { |engine_global|
	engine_global.newmacro_("osc_a_range", r_util.poly_expand_("OscA.Range", polyphony));
	engine_global.newmacro_("osc_a_pulsewidth", r_util.poly_expand_("OscA.PulseWidth", polyphony));
	engine_global.newmacro_("osc_b_range", r_util.poly_expand_("OscB.Range", polyphony));
	engine_global.newmacro_("osc_b_pulsewidth", r_util.poly_expand_("OscB.PulseWidth", polyphony));
	engine_global.newmacro_("osc_a_detune", r_util.poly_expand_("OscA.Tune", polyphony));
	engine_global.newmacro_("osc_b_detune", r_util.poly_expand_("OscB.Tune", polyphony));
	engine_global.newmacro_("lfo_frequency", r_util.poly_expand_("LFO.Frequency", polyphony));
	engine_global.newmacro_("osc_a_pwm", r_util.poly_expand_("OscA.PWM", polyphony));
	engine_global.newmacro_("osc_b_pwm", r_util.poly_expand_("OscB.PWM", polyphony));
	engine_global.newmacro_("filter_frequency", r_util.poly_expand_("Filter.Frequency", polyphony));
	engine_global.newmacro_("filter_resonance", r_util.poly_expand_("Filter.Resonance", polyphony));
	engine_global.newmacro_("env_to_filter_fm", r_util.poly_expand_("Filter.FM", polyphony));
	engine_global.newmacro_("env_attack", r_util.poly_expand_("Env.Attack", polyphony));
	engine_global.newmacro_("env_decay", r_util.poly_expand_("Env.Decay", polyphony));
	engine_global.newmacro_("env_sustain", r_util.poly_expand_("Env.Sustain", polyphony));
	engine_global.newmacro_("env_release", r_util.poly_expand_("Env.Release", polyphony));
};

var get_param_specs = { |engine_global|
	[
		get_filter_frequency_param_spec.value(engine_global),
		get_filter_resonance_param_spec.value(engine_global),
		get_osc_a_range_param_spec.value(engine_global),
		get_osc_b_range_param_spec.value(engine_global),
		get_osc_a_pulsewidth_param_spec.value(engine_global),
		get_osc_b_pulsewidth_param_spec.value(engine_global),
		get_osc_detune_param_spec.value(engine_global),
		get_lfo_frequency_param_spec.value(engine_global),
		get_lfo_to_osc_pwm_param_spec.value(engine_global),
		get_env_to_filter_fm_param_spec.value(engine_global),
		get_env_attack_param_spec.value(engine_global),
		get_env_decay_param_spec.value(engine_global),
		get_env_sustain_param_spec.value(engine_global),
		get_env_release_param_spec.value(engine_global),
		get_output_level_param_spec.value(engine_global)
	];
};

var get_filter_frequency_param_spec = { |engine_global|
	var spec = r_specs[\LPFilter][\Frequency].copy();
	spec.maxval = 8000;
	spec.minval = 10;
	spec.default = 500;

	IdentityDictionary[
		\id -> "filter_frequency",
		\type -> "control",
		\name -> "Filter Frequency",
		\narrow_name -> "FREQ",
		\controlspec -> spec,
		\narrow_formatter -> formatters[\adaptive_freq],
		\action -> { |value|
			engine_global.macroset_("filter_frequency", value);
		}
	];
};

var get_filter_resonance_param_spec = { |engine_global|
	var spec = r_specs[\LPFilter][\Resonance].copy();
	spec.default = 0.2;

	IdentityDictionary[
		\id -> "filter_resonance",
		\type -> "control",
		\name -> "Filter Resonance",
		\narrow_name -> "RES",
		\controlspec -> spec,
		\formatter -> formatters[\percentage],
		\action -> { |value|
			engine_global.macroset_("filter_resonance", value);
		}
	];
};

var get_osc_a_range_param_spec = { |engine_global|
	IdentityDictionary[
		\id -> "osc_a_range",
		\type -> "control",
		\name -> "Osc A Range",
		\narrow_name -> "A.RNG",
		\controlspec -> r_specs[\PulseOsc][\Range],
		\formatter -> formatters[\round].value(1),
		\narrow_formatter -> formatters[\range],
		\action -> { |value|
			engine_global.macroset_("osc_a_range", value);
		}
	];
};

var get_osc_b_range_param_spec = { |engine_global|
	IdentityDictionary[
		\id -> "osc_b_range",
		\type -> "control",
		\name -> "Osc B Range",
		\narrow_name -> "B.RNG",
		\controlspec -> r_specs[\PulseOsc][\Range],
		\formatter -> formatters[\round].value(1),
		\narrow_formatter -> formatters[\range],
		\action -> { |value|
			engine_global.macroset_("osc_b_range", value);
		}
	];
};

var get_osc_a_pulsewidth_param_spec = { |engine_global|
	var spec = r_specs[\PulseOsc][\PulseWidth].copy();
	spec.default = 0.88;

	IdentityDictionary[
		\id -> "osc_a_pulsewidth",
		\type -> "control",
		\name -> "Osc A Pulse Width",
		\narrow_name -> "A.PW",
		\controlspec -> spec,
		\formatter -> formatters[\percentage],
		\action -> { |value|
			engine_global.macroset_("osc_a_pulsewidth", value);
		}
	];
};

var get_osc_b_pulsewidth_param_spec = { |engine_global|
	var spec = r_specs[\PulseOsc][\PulseWidth].copy();
	spec.default = 0.88;

	IdentityDictionary[
		\id -> "osc_b_pulsewidth",
		\type -> "control",
		\name -> "Osc B Pulse Width",
		\narrow_name -> "B.PW",
		\controlspec -> spec,
		\formatter -> formatters[\percentage],
		\action -> { |value|
			engine_global.macroset_("osc_b_pulsewidth", value);
		}
	];
};

var get_osc_detune_param_spec = { |engine_global|
	var spec = \unipolar.asSpec.copy();
	spec.default = 0.36;

	IdentityDictionary[
		\id -> "osc_detune",
		\type -> "control",
		\name -> "Detune",
		\narrow_name -> "DETUN",
		\controlspec -> spec,
		\formatter -> formatters[\percentage],
		\action -> { |value|
			engine_global.macroset_("osc_a_detune", -1 * value * 20);
			engine_global.macroset_("osc_b_detune", value * 20);
		}
	];
};

var get_lfo_frequency_param_spec = { |engine_global|
	var spec = r_specs[\MultiLFO][\Frequency].copy();
	spec.default = 0.125;

	IdentityDictionary[
		\id -> "lfo_frequency",
		\type -> "control",
		\name -> "PWM Rate",
		\narrow_name -> "LFO",
		\controlspec -> spec,
		\formatter -> formatters[\round].value(0.001),
		\narrow_formatter -> formatters[\adaptive_freq],
		\action -> { |value|
			engine_global.macroset_("lfo_frequency", value);
		}
	];
};

var get_lfo_to_osc_pwm_param_spec = { |engine_global|
	var spec = \unipolar.asSpec.copy();
	spec.default = 0.46;

	IdentityDictionary[
		\id -> "lfo_to_osc_pwm",
		\type -> "control",
		\name -> "PWM Depth",
		\narrow_name -> "PWM",
		\controlspec -> spec,
		\formatter -> formatters[\percentage],
		\action -> { |value|
			engine_global.macroset_("osc_a_pwm", value*0.76);
			engine_global.macroset_("osc_b_pwm", value*0.56);
		}
	];
};

var get_env_to_filter_fm_param_spec = { |engine_global|
	var spec = r_specs[\LPFilter][\FM].copy();
	spec.default = 0.35;

	IdentityDictionary[
		\id -> "env_to_filter_fm",
		\type -> "control",
		\name -> "Env > Filter Frequency",
		\narrow_name -> "E>FIL",
		\controlspec -> spec,
		\formatter -> formatters[\percentage],
		\action -> { |value|
			engine_global.macroset_("env_to_filter_fm", value);
		}
	];
};

var get_env_attack_param_spec = { |engine_global|
	var spec = r_specs[\ADSREnv][\Attack].copy();
	spec.default = 1;

	IdentityDictionary[
		\id -> "env_attack",
		\type -> "control",
		\name -> "Env Attack",
		\narrow_name -> "E.ATK",
		\controlspec -> spec,
		\narrow_formatter -> formatters[\adaptive_time],
		\action -> { |value|
			engine_global.macroset_("env_attack", value);
		}
	];
};

var get_env_decay_param_spec = { |engine_global|
	var spec = r_specs[\ADSREnv][\Decay].copy();
	spec.default = 200;

	IdentityDictionary[
		\id -> "env_decay",
		\type -> "control",
		\name -> "Env Decay",
		\narrow_name -> "E.DEC",
		\controlspec -> spec,
		\narrow_formatter -> formatters[\adaptive_time],
		\action -> { |value|
			engine_global.macroset_("env_decay", value);
		}
	];
};

var get_env_sustain_param_spec = { |engine_global|
	var spec = r_specs[\ADSREnv][\Sustain].copy();
	spec.default = 0.5;

	IdentityDictionary[
		\id -> "env_sustain",
		\type -> "control",
		\name -> "Env Sustain",
		\narrow_name -> "E.SUS",
		\controlspec -> spec,
		\formatter -> formatters[\percentage],
		\action -> { |value|
			engine_global.macroset_("env_sustain", value);
		}
	];
};

var get_env_release_param_spec = { |engine_global|
	var spec = r_specs[\ADSREnv][\Release].copy();
	spec.default = 500;

	IdentityDictionary[
		\id -> "env_release",
		\type -> "control",
		\name -> "Env Release",
		\narrow_name -> "E.REL",
		\controlspec -> spec,
		\narrow_formatter -> formatters[\adaptive_time],
		\action -> { |value|
			engine_global.macroset_("env_release", value);
		}
	];
};

var get_output_level_param_spec = { |engine_global|
	var spec = r_specs['MGain']['Gain'].copy;
	spec.default = -10;

	IdentityDictionary[
		\id -> "output_level",
		\type -> "control",
		\name -> "Amplifier.Gain",
		\controlspec -> spec,
		\formatter -> formatters.round_(0.1),
		\action -> { |value| engine_global.set_("Amplifier.Gain", value) }
	];
};

var note_on = { |engine_global, note, velocity|
	if (note_slots[note].isNil) {
		var slot = voice_allocator.get__();
		var voicenum = slot[\id__]; // TODO: + 1
		trig_voice.value(engine_global, voicenum, note);
		slot[\on_release__] = {
			release_voice.value(engine_global, voicenum);
			note_slots[note] = nil;
		};
		note_slots[note] = slot;
		note_downs[voicenum] = note;
	};
};

var trig_voice = { |engine_global, voicenum, note|
	engine_global.bulkset_("FreqGate"++voicenum++".Gate 1 FreqGate"++voicenum++".Frequency "++note.midicps); // TODO
	// TODO postln("FreqGate"++(voicenum+1)++".Gate 1 FreqGate"++(voicenum+1)++".Frequency "++note.midicps);
};

var release_voice = { |engine_global, voicenum|
	engine_global.bulkset_("FreqGate"++voicenum++".Gate 0"); // TODO
	// TODO postln("FreqGate"++(voicenum+1)++".Gate 0");
};

var note_off = { |engine_global, note|
	var slot = note_slots[note];
	if (slot.notNil) {
		voice_allocator.release__(slot);
		note_downs[slot[\id]] = nil;
	};
};

var module = IdentityDictionary[
	\init -> init,
	\note_on -> note_on,
	\note_off -> note_off,
];

module
)
