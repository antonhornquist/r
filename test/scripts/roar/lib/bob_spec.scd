(
var include_relative = { |relative_path|
	var path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ relative_path).standardizePath;
	if (File.exists(path)) {
		this.executeFile(path);
	} {
		Error("include_relative: file % does not exist".format(path.quote)).throw;
	};
};

var r_specs = include_relative.value("r_specs.scd");
var formatters = include_relative.value("formatters.scd");
var custom_formatters = include_relative.value("formatters.scd"); // TODO: ... this
var capped_list = include_relative.value("capped_list.scd");
var capped_list_create = capped_list[\create];
var capped_list_push = capped_list[\push];

var init = { |config|
	var engine_global = config[\engine_global] ?? { Error("engine global is required").throw }; // TODO: make this more declarative: do not invoke engine global here, only send back metadata
	var visual_buf_size = config[\visual_buf_size] ?? { Error("visual_buf_size is required").throw };
	var visual_value_bufs = create_visual_values_bufs.value(visual_buf_size);

	init_r_modules.value(engine_global);

	(
		param_specs: get_param_specs.value(engine_global),
		poll_specs: get_poll_specs.value(visual_value_bufs),
		visual_values: visual_value_bufs // TODO: rename key to visual_value_bufs too
	)
};

var init_r_modules = { |engine_global|
	create_modules.value(engine_global);
	set_static_module_params.value(engine_global);
	connect_modules.value(engine_global);
	engine_global.pollvisual_(1, "FilterL=Frequency");
};

var create_modules = { |engine_global|
	engine_global.new_("LFO", "MultiLFO");
	engine_global.new_("SoundIn", "SoundIn");
	engine_global.new_("EnvF", "EnvF");
	engine_global.new_("ModMix", "LinMixer");
	engine_global.new_("FilterL", "LPLadder");
	engine_global.new_("FilterR", "LPLadder");
	engine_global.new_("Amplifier", "SGain");
	engine_global.new_("SoundOut", "SoundOut");
};

var set_static_module_params = { |engine_global|
	engine_global.set_("FilterL.FM", 1);
	engine_global.set_("FilterR.FM", 1);
	engine_global.set_("ModMix.Out", 1);
};

var connect_modules = { |engine_global|
	engine_global.connect_("SoundIn/Left", "FilterL*In");
	engine_global.connect_("SoundIn/Right", "FilterR*In");
	engine_global.connect_("LFO/Sine", "ModMix*In1");
	engine_global.connect_("SoundIn/Left", "EnvF*In");
	engine_global.connect_("EnvF/Env", "ModMix*In2");
	engine_global.connect_("ModMix/Out", "FilterL*FM");
	engine_global.connect_("ModMix/Out", "FilterR*FM");
	engine_global.connect_("FilterL/Out", "Amplifier*Left");
	engine_global.connect_("FilterR/Out", "Amplifier*Right");
	engine_global.connect_("Amplifier/Left", "SoundOut*Left");
	engine_global.connect_("Amplifier/Right", "SoundOut*Right");
};

var create_visual_values_bufs = { |visual_buf_size|
	IdentityDictionary[
		\cutoff -> capped_list_create.value(visual_buf_size)
	];
};

var get_poll_specs = { |visual_values|
	[
		get_cutoff_poll_spec.value(visual_values),
	];
};

var get_cutoff_poll_spec = { |visual_values|
	var spec = r_specs[\LPLadder][\Frequency].copy();
	spec.default = 1000;
	spec.minval = 20; // TODO: this might not be right
	spec.maxval = 10000; // TODO: this might not be right
	IdentityDictionary[
		\id -> "cutoff",
		\handler -> { |value|
			var visual_value = spec.unmap(value);
			capped_list_push.value(visual_values[\cutoff], visual_value);
		}
	];
};

var get_param_specs = { |engine_global|
	[
		get_cutoff_param_spec.value(engine_global),
		get_resonance_param_spec.value(engine_global),
		get_lfo_rate_param_spec.value(engine_global),
		get_lfo_to_cutoff_param_spec.value(engine_global),
		get_env_attack_param_spec.value(engine_global),
		env_decay_param_spec.value(engine_global),
		env_sensitivity_param_spec.value(engine_global),
		env_to_cutoff_param_spec.value(engine_global),
		get_output_level_param_spec.value(engine_global)
	];
};

var get_cutoff_param_spec = { |engine_global|
	var spec = r_specs[\LPLadder][\Frequency].copy();
	spec.default = 1000;
	spec.minval = 20;
	spec.maxval = 10000;

	IdentityDictionary[
		\id -> "cutoff",
		\type -> "control",
		\name -> "Cutoff",
		\narrow_name -> "CUTOFF",
		\narrow_formatter -> custom_formatters[\adaptive_freq],
		\controlspec -> spec,
		\action -> { |value|
			engine_global.set_("FilterL.Frequency", value);
			engine_global.set_("FilterR.Frequency", value);
		}
	]
};

var get_resonance_param_spec = { |engine_global|
	var spec = r_specs[\LPLadder][\Resonance].copy();
	spec.default = 0.5;

	IdentityDictionary[
		\id -> "resonance",
		\type -> "control",
		\name -> "Resonance",
		\narrow_name -> "RES",
		\controlspec -> spec,
		\formatter -> formatters[\percentage],
		\action -> { |value|
			engine_global.set_("FilterL.Resonance", value);
			engine_global.set_("FilterR.Resonance", value);
		}
	]
};

var get_lfo_rate_param_spec = { |engine_global|
	var spec = r_specs[\MultiLFO][\Frequency].copy();
	spec.default = 0.5;

	IdentityDictionary[
		\id -> "lfo_rate",
		\type -> "control",
		\name -> "LFO Rate",
		\narrow_name -> "LFO",
		\controlspec -> spec,
		\formatter -> formatters[\round].value(0.001),
		\narrow_formatter -> custom_formatters[\adaptive_freq],
		\action -> { |value|
			engine_global.set_("LFO.Frequency", value);
		}
	]
};

var get_lfo_to_cutoff_param_spec = { |engine_global|
	var spec = r_specs[\LinMixer][\In1];
	spec.default = 0.1;

	IdentityDictionary[
		\id -> "lfo_to_cutoff",
		\type -> "control",
		\name -> "LFO > Cutoff",
		\name -> "L>FRQ",
		\controlspec -> spec,
		\formatter -> formatters[\percentage],
		\action -> { |value|
			engine_global.set_("ModMix.In1", value);
		}
	]
};

var get_env_attack_param_spec = { |engine_global|
	var spec = r_specs[\ADSREnv][\Attack].copy();
	spec.default = 50;

	IdentityDictionary[
		\id -> "envf_attack",
		\type -> "control",
		\name -> "EnvF Attack",
		\narrow_name -> "E.ATK",
		\controlspec -> spec,
		\narrow_formatter -> custom_formatters[\adaptive_time],
		\action -> { |value|
			engine_global.set_("EnvF.Attack", value);
		}
	]
};

var env_decay_param_spec = { |engine_global|
	var spec = r_specs[\ADSREnv][\Decay].copy();
	spec.default = 100;

	IdentityDictionary[
		\id -> "envf_decay",
		\type -> "control",
		\name -> "EnvF Decay",
		\narrow_name -> "E.DEC",
		\controlspec -> spec,
		\narrow_formatter -> custom_formatters[\adaptive_time],
		\action -> { |value|
			engine_global.set_("EnvF.Decay", value);
		}
	]
};

var env_sensitivity_param_spec = { |engine_global|
	IdentityDictionary[
		\id -> "envf_sensitivity",
		\type -> "control",
		\name -> "EnvF Sensitivity",
		\narrow_name -> "E.SNS",
		\controlspec -> ControlSpec.new(0, 1),
		\formatter -> formatters[\percentage],
		\action -> { |value|
			engine_global.set_("EnvF.Sensitivity", value);
		}
	]
};

var env_to_cutoff_param_spec = { |engine_global|
	var spec = r_specs[\LinMixer][\In2].copy();
	spec.default = 0.1;

	IdentityDictionary[
		\id -> "env_to_cutoff",
		\type -> "control",
		\name -> "Env > Cutoff",
		\narrow_name -> "E>FRQ",
		\controlspec -> spec,
		\formatter -> formatters[\percentage],
		\action -> { |value|
			engine_global.set_("ModMix.In2", value);
		}
	]
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
		\action -> { |value|
			engine_global.set_("Amplifier.Gain", value);
		}
	];
};

var module = IdentityDictionary[
	\init -> init
];

module
)
