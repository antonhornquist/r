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
var capped_list = include_relative.value("capped_list.scd");
var capped_list_create = capped_list[\create];
var capped_list_push = capped_list[\push];

var visual_values;

var init = { |visual_buf_size|
	var r_polls, r_params;
	init_r_modules.value();
	visual_values = init_visual_values_bufs.value(visual_buf_size);
	r_polls = init_r_polls.value();
	r_params = init_r_params.value();

	[r_polls, visual_values, r_params];
};

var init_r_modules = {
	create_modules.value();
	set_static_module_params.value();
	connect_modules.value();
	~engine.pollvisual_(1, "FilterL=Frequency");
};

var create_modules = {
	~engine.new_("LFO", "MultiLFO");
	~engine.new_("SoundIn", "SoundIn");
	~engine.new_("EnvF", "EnvF");
	~engine.new_("ModMix", "LinMixer");
	~engine.new_("FilterL", "LPLadder");
	~engine.new_("FilterR", "LPLadder");
	~engine.new_("Amplifier", "SGain");
	~engine.new_("SoundOut", "SoundOut");
};

var set_static_module_params = {
	~engine.set_("FilterL.FM", 1);
	~engine.set_("FilterR.FM", 1);
	~engine.set_("ModMix.Out", 1);
};

var connect_modules = {
	~engine.connect_("SoundIn/Left", "FilterL*In");
	~engine.connect_("SoundIn/Right", "FilterR*In");
	~engine.connect_("LFO/Sine", "ModMix*In1");
	~engine.connect_("SoundIn/Left", "EnvF*In");
	~engine.connect_("EnvF/Env", "ModMix*In2");
	~engine.connect_("ModMix/Out", "FilterL*FM");
	~engine.connect_("ModMix/Out", "FilterR*FM");
	~engine.connect_("FilterL/Out", "Amplifier*Left");
	~engine.connect_("FilterR/Out", "Amplifier*Right");
	~engine.connect_("Amplifier/Left", "SoundOut*Left");
	~engine.connect_("Amplifier/Right", "SoundOut*Right");
};

var init_visual_values_bufs = { |visual_buf_size|
	IdentityDictionary[
		\cutoff -> capped_list_create.value(visual_buf_size)
	];
};

var cutoff_spec;

var init_r_polls = {
	[
		IdentityDictionary[
			\id -> "cutoff",
			\handler -> { |value|
				var visual_value = cutoff_spec.unmap(value);
				capped_list_push.value(visual_values[\cutoff], visual_value);
			}
		]
	]
};

var init_r_params = {
	var r_params = [];

	var resonance_spec;
	var lfo_rate_spec;
	var lfo_to_cutoff_spec;
	var env_attack_spec;
	var env_decay_spec;
	var env_to_cutoff_spec;

	cutoff_spec = r_specs[\LPLadder][\Frequency].copy();
	cutoff_spec.default = 1000;
	cutoff_spec.minval = 20;
	cutoff_spec.maxval = 10000;

	r_params = r_params.add(
		IdentityDictionary[
			\id -> "cutoff",
			\type -> "control",
			\name -> "Cutoff",
			\controlspec -> cutoff_spec,
			\action -> { |value|
				~engine.set_("FilterL.Frequency", value);
				~engine.set_("FilterR.Frequency", value);
			}
		]
	);

	resonance_spec = r_specs[\LPLadder][\Resonance].copy();
	resonance_spec.default = 0.5;

	r_params = r_params.add(
		IdentityDictionary[
			\id -> "resonance",
			\type -> "control",
			\name -> "Resonance",
			\controlspec -> resonance_spec,
			\formatter -> formatters[\percentage],
			\action -> { |value|
				~engine.set_("FilterL.Resonance", value);
				~engine.set_("FilterR.Resonance", value);
			}
		]
	);

	lfo_rate_spec = r_specs[\MultiLFO][\Frequency].copy();
	lfo_rate_spec.default = 0.5;

	r_params = r_params.add(
		IdentityDictionary[
			\id -> "lfo_rate",
			\type -> "control",
			\name -> "LFO Rate",
			\controlspec -> lfo_rate_spec,
			\formatter -> formatters[\round].value(0.001),
			\action -> { |value|
				~engine.set_("LFO.Frequency", value);
			}
		]
	);

	lfo_to_cutoff_spec = r_specs[\LinMixer][\In1];
	lfo_to_cutoff_spec.default = 0.1;

	r_params = r_params.add(
		IdentityDictionary[
			\id -> "lfo_to_cutoff",
			\type -> "control",
			\name -> "LFO > Cutoff",
			\controlspec -> lfo_to_cutoff_spec,
			\formatter -> formatters[\percentage],
			\action -> { |value|
				~engine.set_("ModMix.In1", value);
			}
		]
	);

	env_attack_spec = r_specs[\ADSREnv][\Attack].copy();
	env_attack_spec.default = 50;

	r_params = r_params.add(
		IdentityDictionary[
			\id -> "envf_attack",
			\type -> "control",
			\name -> "EnvF Attack",
			\controlspec -> env_attack_spec,
			\action -> { |value|
				~engine.set_("EnvF.Attack", value);
			}
		]
	);

	env_decay_spec = r_specs[\ADSREnv][\Decay].copy();
	env_decay_spec.default = 100;

	r_params = r_params.add(
		IdentityDictionary[
			\id -> "envf_decay",
			\type -> "control",
			\name -> "EnvF Decay",
			\controlspec -> env_decay_spec,
			\action -> { |value|
				~engine.set_("EnvF.Decay", value);
			}
		]
	);

	r_params = r_params.add(
		IdentityDictionary[
			\id -> "envf_sensitivity",
			\type -> "control",
			\name -> "EnvF Sensitivity",
			\controlspec -> ControlSpec.new(0, 1),
			\formatter -> formatters[\percentage],
			\action -> { |value|
				~engine.set_("EnvF.Sensitivity", value);
			}
		]
	);

	env_to_cutoff_spec = r_specs[\LinMixer][\In2].copy();
	env_to_cutoff_spec.default = 0.1;

	r_params = r_params.add(
		IdentityDictionary[
			\id -> "env_to_cutoff",
			\type -> "control",
			\name -> "Env > Cutoff",
			\controlspec -> env_to_cutoff_spec,
			\formatter -> formatters[\percentage],
			\action -> { |value|
				~engine.set_("ModMix.In2", value);
			}
		]
	);

	r_params = r_params.add(add_output_level_param.value);

	r_params;
};

var add_output_level_param = {
	var spec = r_specs['MGain']['Gain'].copy;
	spec.default = -10;

	IdentityDictionary[
		\id -> "output_level",
		\type -> "control",
		\name -> "Amplifier.Gain",
		\controlspec -> spec,
		\formatter -> formatters.round_(0.1),
		\action -> { |value| ~engine.set_("Amplifier.Gain", value) }
	];
};

var module = IdentityDictionary[
	\init -> init
];

module
)
