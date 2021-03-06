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
	connect_modules.value(engine_global);
	engine_global.pollvisual_(1, "FreqShift=Frequency");
	engine_global.pollvisual_(2, "PitchShift=PitchRatio");
};

var create_modules = { |engine_global|
	engine_global.new_("LFO", "MultiLFO");
	engine_global.new_("SoundIn", "SoundIn");
	engine_global.new_("PitchShift", "PShift");
	engine_global.new_("FreqShift", "FShift");
	engine_global.new_("Amplifier", "SGain");
	engine_global.new_("SoundOut", "SoundOut");
};

var connect_modules = { |engine_global|
	engine_global.connect_("LFO/Sine", "FreqShift*FM");
	engine_global.connect_("LFO/Sine", "PitchShift*PitchRatioModulation");

	engine_global.connect_("SoundIn/Left", "PitchShift*Left");
	engine_global.connect_("SoundIn/Right", "PitchShift*Right");
	engine_global.connect_("PitchShift/Left", "FreqShift*Left");
	engine_global.connect_("PitchShift/Right", "FreqShift*Right");
	engine_global.connect_("FreqShift/Left", "Amplifier*Left");
	engine_global.connect_("FreqShift/Right", "Amplifier*Right");
	engine_global.connect_("Amplifier/Left", "SoundOut*Left");
	engine_global.connect_("Amplifier/Right", "SoundOut*Right");
};

var create_visual_values_bufs = { |visual_buf_size|
	IdentityDictionary[
		\freq_shift -> capped_list_create.value(visual_buf_size),
		\pitch_ratio -> capped_list_create.value(visual_buf_size)
	];
};

var get_poll_specs = { |visual_values|
	[
		get_freq_shift_poll_spec.value(visual_values),
		get_pitch_ratio_poll_spec.value(visual_values)
	];
};

var get_freq_shift_poll_spec = { |visual_values|
	IdentityDictionary[
		\id -> "freq_shift",
		\handler -> { |value|
			var visual_value = r_specs[\FShift][\Frequency].unmap(value);
			capped_list_push.value(visual_values[\freq_shift], visual_value);
		}
	]
};

var get_pitch_ratio_poll_spec = { |visual_values|
	IdentityDictionary[
		\id -> "pitch_ratio",
		\handler -> { |value|
			var visual_value = r_specs[\PShift][\PitchRatio].unmap(value);
			capped_list_push.value(visual_values[\pitch_ratio], visual_value);
		}
	]
};

var get_param_specs = { |engine_global|
	[
		get_freq_shift_param_spec.value(engine_global),
		get_pitch_ratio_param_spec.value(engine_global),
		get_pitch_dispersion_param_spec.value(engine_global),
		get_time_dispersion_param_spec.value(engine_global),
		get_lfo_rate_param_spec.value(engine_global),
		get_lfo_to_freq_shift_param_spec.value(engine_global),
		get_lfo_to_pitch_ratio_param_spec.value(engine_global),
		get_output_level_param_spec.value(engine_global)
	];
};

var get_freq_shift_param_spec = { |engine_global|
	IdentityDictionary[
		\type -> "control",
		\id -> "freq_shift",
		\controlspec -> r_specs[\FShift][\Frequency],
		\name -> "Frequency Shift",
		\narrow_name -> "F.SHFT",
		\narrow_formatter -> custom_formatters[\adaptive_freq],
		\action -> { |value|
			engine_global.set_("FreqShift.Frequency", value);
		}
	];
};

var get_pitch_ratio_param_spec = { |engine_global|
	IdentityDictionary[
		\type -> "control",
		\id -> "pitch_ratio",
		\controlspec -> r_specs[\PShift][\PitchRatio],
		\name -> "Pitch Ratio",
		\formatter -> formatters[\percentage],
		\narrow_name -> "P.RAT",
		\action -> { |value|
			engine_global.set_("PitchShift.PitchRatio", value);
		}
	];
};

var get_pitch_dispersion_param_spec = { |engine_global|
	IdentityDictionary[
		\type -> "control",
		\id -> "pitch_dispersion",
		\controlspec -> r_specs[\PShift][\PitchDispersion],
		\formatter -> formatters[\percentage],
		\name -> "Pitch Dispersion",
		\narrow_name -> "P.DISP",
		\action -> { |value|
			engine_global.set_("PitchShift.PitchDispersion", value);
		}
	];
};

var get_time_dispersion_param_spec = { |engine_global|
	IdentityDictionary[
		\type -> "control",
		\id -> "time_dispersion",
		\controlspec -> r_specs[\PShift][\TimeDispersion],
		\formatter -> formatters[\percentage],
		\name -> "Time Dispersion",
		\narrow_name -> "T.DISP",
		\action -> { |value|
			engine_global.set_("PitchShift.TimeDispersion", value);
		}
	]
};

var get_lfo_rate_param_spec = { |engine_global|
	IdentityDictionary[
		\type -> "control",
		\id -> "lfo_rate",
		\controlspec -> r_specs[\MultiLFO][\Frequency],
		\name -> "LFO Frequency",
		\narrow_name -> "LFO.HZ",
		\narrow_formatter -> custom_formatters[\adaptive_freq],
		\action -> { |value|
			engine_global.set_("LFO.Frequency", value);
		}
	]
};

var get_lfo_to_freq_shift_param_spec = { |engine_global|
	IdentityDictionary[
		\type -> "control",
		\id -> "lfo_to_freq_shift",
		\controlspec -> r_specs[\FShift][\FM],
		\name -> "LFO to Frequency Shift",
		\formatter -> formatters[\percentage],
		\narrow_name -> ">F.SHIFT",
		\action -> { |value|
			engine_global.set_("FreqShift.FM", value);
		}
	]
};

var get_lfo_to_pitch_ratio_param_spec = { |engine_global|
	IdentityDictionary[
		\type -> "control",
		\id -> "lfo_to_pitch_ratio",
		\controlspec -> r_specs[\PShift][\PitchRatioModulation],
		\formatter -> formatters[\percentage],
		\name -> "LFO to Pitch Ratio",
		\narrow_name -> ">P.RAT",
		\action -> { |value|
			engine_global.set_("PitchShift.PitchRatioModulation", value);
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
		\action -> { |value| engine_global.set_("Amplifier.Gain", value) }
	];
};

var module = IdentityDictionary[
	\init -> init
];

module
)
