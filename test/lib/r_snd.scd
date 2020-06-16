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

var visual_values;

var init = { |visual_buf_size|
	var r_polls, r_params;
	init_r_modules.value();
	r_params = init_r_params.value();

	[nil, nil, r_params];
};

var init_r_modules = {
	create_modules.value();
	set_static_module_params.value();
	connect_modules.value();
};

var create_modules = {
	~engine.new_("FreqGate", "FreqGate");
	~engine.new_("MultiOsc", "MultiOsc");
	~engine.new_("Filter", "LPLadder");
	~engine.new_("Amplifier", "MGain");
	~engine.new_("SoundOut", "SoundOut");
};

var set_static_module_params = {
	~engine.set_("MultiOsc.FM", 1);
};

var connect_modules = {
	~engine.connect_("FreqGate/Frequency", "MultiOsc*FM");
	~engine.connect_("MultiOsc/Pulse", "Filter*In");
	~engine.connect_("Filter/Out", "Amplifier*In");
	~engine.connect_("Amplifier/Out", "SoundOut*Left");
	~engine.connect_("Amplifier/Out", "SoundOut*Right");
};

var cutoff_spec;

var init_r_params = {
	var r_params = [];

	r_params = r_params.add(
		IdentityDictionary[
			\id -> "frequency",
			\type -> "control",
			\name -> "Frequency",
			\controlspec -> r_specs[\FreqGate][\Frequency],
			\action -> { |value|
				~engine.set_("FreqGate.Frequency", value);
			}
		]
	);

	r_params = r_params.add(
		IdentityDictionary[
			\id -> "pulse_width",
			\type -> "control",
			\name -> "Pulse Width",
			\controlspec -> r_specs[\MultiOsc][\PulseWidth],
			\action -> { |value|
				~engine.set_("MultiOsc.PulseWidth", value);
			}
		]
	);

	r_params = r_params.add(
		IdentityDictionary[
			\id -> "cutoff",
			\type -> "control",
			\name -> "Cutoff",
			\controlspec -> r_specs[\LPLadder][\Frequency],
			\action -> { |value|
				~engine.set_("Filter.Frequency", value);
			}
		]
	);

	r_params = r_params.add(
		IdentityDictionary[
			\id -> "resonance",
			\type -> "control",
			\name -> "Resonance",
			\controlspec -> r_specs[\LPLadder][\Resonance],
			\formatter -> formatters[\percentage],
			\action -> { |value|
				~engine.set_("Filter.Resonance", value);
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
