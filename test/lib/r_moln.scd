(
var include_relative = { |relative_path|
	var path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ relative_path).standardizePath;
	this.executeFile(path);
};

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
				~engine.new_(name++voicenum, kind);
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
			~engine.set_(r_util.param_voice_ref_(module, param, voicenum), value);
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
			~engine.connect_(sourcemodule++voicenum++"/"++outputref, destmodule++voicenum++"*"++inputref);
		};
	},
);

var formatters = include_relative.value("formatters.scd");
var capped_list = include_relative.value("capped_list.scd");
var capped_list_create = capped_list[\create];
var capped_list_push = capped_list[\push];
var voice = include_relative.value("voice.scd");
var voice_new = voice[\voice_new];

var polyphony = 5;
var note_downs = [];
var note_slots = [];
var voice_allocator;

var visual_values;

var init = { |visual_buf_size|
	var r_params;
	voice_allocator = voice_new.value(polyphony);
	init_r_modules.value();
	r_params = init_r_params.value();

	[nil, nil, r_params];
};

var init_r_modules = {
	create_modules.value();
	set_static_module_params.value();
	connect_modules.value();
	create_macros.value();
};

var create_modules = {
	r_engine.poly_new_("FreqGate", "FreqGate", polyphony);
	r_engine.poly_new_("LFO", "SineLFO", polyphony);
	r_engine.poly_new_("Env", "ADSREnv", polyphony);
	r_engine.poly_new_("OscA", "PulseOsc", polyphony);
	r_engine.poly_new_("OscB", "PulseOsc", polyphony);
	r_engine.poly_new_("Filter", "LPFilter", polyphony);
	r_engine.poly_new_("Amp", "Amp", polyphony);

	~engine.new_("SoundOut", "SoundOut")
};

var set_static_module_params = {
	r_engine.poly_set_("OscA.FM", 1, polyphony);
	r_engine.poly_set_("OscB.FM", 1, polyphony);
	r_engine.poly_set_("Filter.AudioLevel", 1, polyphony);
};

var connect_modules = {
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
		~engine.connect_("Amp"++voicenum++"/Out", "SoundOut*Left");
		~engine.connect_("Amp"++voicenum++"/Out", "SoundOut*Right");
	};
};

var create_macros = {
	~engine.newmacro_("osc_a_range", r_util.poly_expand_("OscA.Range", polyphony));
	~engine.newmacro_("osc_a_pulsewidth", r_util.poly_expand_("OscA.PulseWidth", polyphony));
	~engine.newmacro_("osc_b_range", r_util.poly_expand_("OscB.Range", polyphony));
	~engine.newmacro_("osc_b_pulsewidth", r_util.poly_expand_("OscB.PulseWidth", polyphony));
	~engine.newmacro_("osc_a_detune", r_util.poly_expand_("OscA.Tune", polyphony));
	~engine.newmacro_("osc_b_detune", r_util.poly_expand_("OscB.Tune", polyphony));
	~engine.newmacro_("lfo_frequency", r_util.poly_expand_("LFO.Frequency", polyphony));
	~engine.newmacro_("osc_a_pwm", r_util.poly_expand_("OscA.PWM", polyphony));
	~engine.newmacro_("osc_b_pwm", r_util.poly_expand_("OscB.PWM", polyphony));
	~engine.newmacro_("filter_frequency", r_util.poly_expand_("Filter.Frequency", polyphony));
	~engine.newmacro_("filter_resonance", r_util.poly_expand_("Filter.Resonance", polyphony));
	~engine.newmacro_("env_to_filter_fm", r_util.poly_expand_("Filter.FM", polyphony));
	~engine.newmacro_("env_attack", r_util.poly_expand_("Env.Attack", polyphony));
	~engine.newmacro_("env_decay", r_util.poly_expand_("Env.Decay", polyphony));
	~engine.newmacro_("env_sustain", r_util.poly_expand_("Env.Sustain", polyphony));
	~engine.newmacro_("env_release", r_util.poly_expand_("Env.Release", polyphony));
};

var init_r_params = {
	var r_params = [
		init_filter_frequency_param.value,
		init_filter_resonance_param.value,
		init_osc_a_range_param.value,
		init_osc_b_range_param.value,
		init_osc_a_pulsewidth_param.value,
		init_osc_b_pulsewidth_param.value,
		init_osc_detune_param.value,
		init_lfo_frequency_param.value,
		init_lfo_to_osc_pwm_param.value,
		init_env_to_filter_fm_param.value,
		init_env_attack_param.value,
		init_env_decay_param.value,
		init_env_sustain_param.value,
		init_env_release_param.value
	];

	r_params;
};

var init_filter_frequency_param = {
	var spec = r_specs[\LPFilter][\Frequency].copy();
	spec.maxval = 8000;
	spec.minval = 10;
	spec.default = 500;

	IdentityDictionary[
		\id -> "filter_frequency",
		\type -> "control",
		\name -> "Filter Frequency",
		\controlspec -> spec,
		\action -> { |value|
			~engine.macroset_("filter_frequency", value);
		}
	];
};

var init_filter_resonance_param = {
	var spec = r_specs[\LPFilter][\Resonance].copy();
	spec.default = 0.2;

	IdentityDictionary[
		\id -> "filter_resonance",
		\type -> "control",
		\name -> "Filter Resonance",
		\controlspec -> spec,
		\action -> { |value|
			~engine.macroset_("filter_resonance", value);
		}
	];
};

var init_osc_a_range_param = {
	IdentityDictionary[
		\id -> "osc_a_range",
		\type -> "control",
		\name -> "Osc A Range",
		\controlspec -> r_specs[\PulseOsc][\Range],
		\formatter -> formatters[\round].value(1),
		\action -> { |value|
			~engine.macroset_("osc_a_range", value);
		}
	];
};

var init_osc_b_range_param = {
	IdentityDictionary[
		\id -> "osc_b_range",
		\type -> "control",
		\name -> "Osc B Range",
		\controlspec -> r_specs[\PulseOsc][\Range],
		\formatter -> formatters[\round].value(1),
		\action -> { |value|
			~engine.macroset_("osc_b_range", value);
		}
	];
};

var init_osc_a_pulsewidth_param = {
	var spec = r_specs[\PulseOsc][\PulseWidth].copy();
	spec.default = 0.88;

	IdentityDictionary[
		\id -> "osc_a_pulsewidth",
		\type -> "control",
		\name -> "Osc A Pulse Width",
		\controlspec -> spec,
		\formatter -> formatters[\percentage],
		\action -> { |value|
			~engine.macroset_("osc_a_pulsewidth", value);
		}
	];
};

var init_osc_b_pulsewidth_param = {
	var spec = r_specs[\PulseOsc][\PulseWidth].copy();
	spec.default = 0.88;

	IdentityDictionary[
		\id -> "osc_b_pulsewidth",
		\type -> "control",
		\name -> "Osc B Pulse Width",
		\controlspec -> spec,
		\formatter -> formatters[\percentage],
		\action -> { |value|
			~engine.macroset_("osc_b_pulsewidth", value);
		}
	];
};

var init_osc_detune_param = {
	var spec = \unipolar.asSpec.copy();
	spec.default = 0.36;

	IdentityDictionary[
		\id -> "osc_detune",
		\type -> "control",
		\name -> "Detune",
		\controlspec -> spec,
		\formatter -> formatters[\percentage],
		\action -> { |value|
			~engine.macroset_("osc_a_detune", -1 * value * 20);
			~engine.macroset_("osc_b_detune", -1 * value * 20);
		}
	];
};

var init_lfo_frequency_param = {
	var spec = r_specs[\MultiLFO][\Frequency].copy();
	spec.default = 0.125;

	IdentityDictionary[
		\id -> "lfo_frequency",
		\type -> "control",
		\name -> "PWM Rate",
		\controlspec -> spec,
		\formatter -> formatters[\round].value(0.001),
		\action -> { |value|
			~engine.macroset_("lfo_frequency", value);
		}
	];
};

var init_lfo_to_osc_pwm_param = {
	var spec = \unipolar.asSpec.copy();
	spec.default = 0.46;

	IdentityDictionary[
		\id -> "lfo_to_osc_pwm",
		\type -> "control",
		\name -> "PWM Depth",
		\controlspec -> spec,
		\formatter -> formatters[\percentage],
		\action -> { |value|
			~engine.macroset_("osc_a_pwm", value*0.76);
			~engine.macroset_("osc_b_pwm", value*0.56);
		}
	];
};

var init_env_to_filter_fm_param = {
	var spec = r_specs[\LPFilter][\FM].copy();
	spec.default = 0.35;

	IdentityDictionary[
		\id -> "env_to_filter_fm",
		\type -> "control",
		\name -> "Env > Filter Frequency",
		\controlspec -> spec,
		\formatter -> formatters[\percentage],
		\action -> { |value|
			~engine.macroset_("env_to_filter_fm", value);
		}
	];
};

var init_env_attack_param = {
	var spec = r_specs[\ADSREnv][\Attack].copy();
	spec.default = 1;

	IdentityDictionary[
		\id -> "env_attack",
		\type -> "control",
		\name -> "Env Attack",
		\controlspec -> spec,
		\action -> { |value|
			~engine.macroset_("env_attack", value);
		}
	];
};

var init_env_decay_param = {
	var spec = r_specs[\ADSREnv][\Decay].copy();
	spec.default = 200;

	IdentityDictionary[
		\id -> "env_decay",
		\type -> "control",
		\name -> "Env Decay",
		\controlspec -> spec,
		\action -> { |value|
			~engine.macroset_("env_decay", value);
		}
	];
};

var init_env_sustain_param = {
	var spec = r_specs[\ADSREnv][\Sustain].copy();
	spec.default = 0.5;

	IdentityDictionary[
		\id -> "env_sustain",
		\type -> "control",
		\name -> "Env Sustain",
		\controlspec -> spec,
		\formatter -> formatters[\percentage],
		\action -> { |value|
			~engine.macroset_("env_sustain", value);
		}
	];
};

var init_env_release_param = {
	var spec = r_specs[\ADSREnv][\Release].copy();
	spec.default = 500;

	IdentityDictionary[
		\id -> "env_release",
		\type -> "control",
		\name -> "Env Release",
		\controlspec -> spec,
		\action -> { |value|
			~engine.macroset_("env_release", value);
		}
	];
};

var note_on = { |note, velocity|
	if (note_slots[note].isNil) {
		var slot = voice_allocator.get_();
		var voicenum = slot[\id_];
		trig_voice.value(voicenum, note);
		slot[\on_release_] = {
			release_voice.value(voicenum);
			note_slots[note] = nil;
		};
		note_slots[note] = slot;
		note_downs[voicenum] = note;
	};
};

var trig_voice = { |voicenum, note|
	//~engine.bulkset_("FreqGate"++voicenum++".Gate 1 FreqGate"++voicenum++".Frequency "++note.midicps);
	postln("FreqGate"++(voicenum+1)++".Gate 1 FreqGate"++(voicenum+1)++".Frequency "++note.midicps);
};

var release_voice = { |voicenum|
	//~engine.bulkset_("FreqGate"++voicenum++".Gate 0");
	postln("FreqGate"++(voicenum+1)++".Gate 0");
};

var note_off = { |note|
	var slot = note_slots[note];
	if (slot.notNil) {
		voice_allocator.release_(slot);
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
