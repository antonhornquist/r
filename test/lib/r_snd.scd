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
var formatters = include_relative.value("formatters.scd"); // TODO: ... this
var custom_formatters = include_relative.value("formatters.scd"); // TODO: ... this

var init = { |config|
	var engine_global = config[\engine_global] ?? { Error("engine global is required").throw }; // TODO: make this more declarative: do not invoke engine global here, only send back metadata
	var visual_buf_size = config[\visual_buf_size] ?? { Error("visual_buf_size is required").throw };
	var parameter_style = config[\parameter_style] ? 'wide';

	init_r_modules.value(engine_global);

	(
		param_specs: get_param_specs.value(engine_global)
	)
};

var init_r_modules = { |engine_global|
	create_modules.value(engine_global);
	set_static_module_params.value(engine_global);
	connect_modules.value(engine_global);
};

var create_modules = { |engine_global|
	engine_global.new_("FreqGate", "FreqGate");
	engine_global.new_("MultiOsc", "MultiOsc");
	engine_global.new_("Filter", "LPLadder");
	engine_global.new_("Amplifier", "MGain");
	engine_global.new_("SoundOut", "SoundOut");
};

var set_static_module_params = { |engine_global|
	engine_global.set_("MultiOsc.FM", 1);
};

var connect_modules = { |engine_global|
	engine_global.connect_("FreqGate/Frequency", "MultiOsc*FM");
	engine_global.connect_("MultiOsc/Pulse", "Filter*In");
	engine_global.connect_("Filter/Out", "Amplifier*In");
	engine_global.connect_("Amplifier/Out", "SoundOut*Left");
	engine_global.connect_("Amplifier/Out", "SoundOut*Right");
};

var get_param_specs = { |engine_global|
	[
		get_osc_frequency_param_spec.value(engine_global),
		get_osc_pulsewidth_param_spec.value(engine_global),
		get_filter_cutoff_param_spec.value(engine_global),
		get_filter_resonance_param_spec.value(engine_global),
		get_output_level_param_spec.value(engine_global)
	];
};

var get_osc_frequency_param_spec = { |engine_global|
	IdentityDictionary[
		\id -> "frequency",
		\type -> "control",
		\controlspec -> r_specs[\FreqGate][\Frequency],
		\name -> "Frequency",
		\narrow_name -> "FREQ",
		\formatter -> custom_formatters[\adaptive_freq],
		\action -> { |value|
			engine_global.set_("FreqGate.Frequency", value);
		}
	];
};

var get_osc_pulsewidth_param_spec = { |engine_global|
	IdentityDictionary[
		\id -> "pulse_width",
		\type -> "control",
		\controlspec -> r_specs[\MultiOsc][\PulseWidth],
		\name -> "Pulse Width",
		\formatter -> formatters[\percentage],
		\narrow_name -> "PW",
		\action -> { |value|
			engine_global.set_("MultiOsc.PulseWidth", value);
		}
	];
};

var get_filter_cutoff_param_spec = { |engine_global|
	var param_spec = IdentityDictionary[
		\id -> "cutoff",
		\type -> "control",
		\controlspec -> r_specs[\LPLadder][\Frequency],
		\name -> "Cutoff",
		\narrow_name -> "CUTOFF",
		\narrow_formatter -> custom_formatters[\adaptive_freq],
		\action -> { |value|
			engine_global.set_("Filter.Frequency", value);
		}
	];

	param_spec;
};

var get_filter_resonance_param_spec = { |engine_global|
	IdentityDictionary[
		\id -> "resonance",
		\type -> "control",
		\controlspec -> r_specs[\LPLadder][\Resonance],
		\name -> "Resonance",
		\formatter -> custom_formatters[\percentage],
		\narrow_name -> "RES",
		\action -> { |value|
			engine_global.set_("Filter.Resonance", value);
		}
	];
};

var get_output_level_param_spec = { |engine_global|
	var spec = r_specs['MGain']['Gain'].copy;
	spec.default = -10;

	IdentityDictionary[
		\id -> "output_level",
		\type -> "control",
		\controlspec -> spec,
		\name -> "Level",
		\narrow_name -> "LVL", // TODO: format to 0 ... 100 in narrow_formatter - don't use raw value in script
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
