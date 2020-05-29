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
	connect_modules.value();
	~engine.pollvisual_(1, "FreqShift=Frequency");
	~engine.pollvisual_(2, "PitchShift=PitchRatio");
};

var create_modules = {
	~engine.new_("LFO", "MultiLFO");
	~engine.new_("SoundIn", "SoundIn");
	~engine.new_("PitchShift", "PShift");
	~engine.new_("FreqShift", "FShift");
	~engine.new_("SoundOut", "SoundOut");
};

var connect_modules = {
	~engine.connect_("LFO/Sine", "FreqShift*FM");
	~engine.connect_("LFO/Sine", "PitchShift*PitchRatioModulation");

	~engine.connect_("SoundIn/Left", "PitchShift*Left");
	~engine.connect_("SoundIn/Right", "PitchShift*Right");
	~engine.connect_("PitchShift/Left", "FreqShift*Left");
	~engine.connect_("PitchShift/Right", "FreqShift*Right");
	~engine.connect_("FreqShift/Left", "SoundOut*Left");
	~engine.connect_("FreqShift/Right", "SoundOut*Right");
};

var init_visual_values_bufs = { |visual_buf_size|
	IdentityDictionary[
		\freq_shift -> capped_list_create.value(visual_buf_size),
		\pitch_ratio -> capped_list_create.value(visual_buf_size)
	];
};

var init_r_polls = {
	[
		IdentityDictionary[
			\id -> "freq_shift",
			\handler -> { |value|
				var visual_value = r_specs[\FShift][\Frequency].unmap(value);
				capped_list_push.value(visual_values.freq_shift, visual_value);
			}
		],
		IdentityDictionary[
			\id -> "pitch_ratio",
			\handler -> { |value|
				var visual_value = r_specs[\PShift][\PitchRatio].unmap(value);
				capped_list_push.value(visual_values.pitch_ratio, visual_value);
			}
		]
	]
};

var init_r_params = {
	var r_params = [];

	r_params = r_params.add(
		IdentityDictionary[
			\type -> "control",
			\id -> "freq_shift",
			\name -> "Freq Shift",
			\controlspec -> r_specs[\FShift][\Frequency],
			\action -> { |value|
				~engine.set_("FreqShift.Frequency", value);
			}
		]
	);

	r_params = r_params.add(
		IdentityDictionary[
			\type -> "control",
			\id -> "pitch_ratio",
			\name -> "Pitch Shift",
			\controlspec -> r_specs[\PShift][\PitchRatio],
			\action -> { |value|
				~engine.set_("PitchShift.PitchRatio", value);
			}
		]
	);

	r_params = r_params.add(
		IdentityDictionary[
			\type -> "control",
			\id -> "pitch_dispersion",
			\name -> "Pitch Dispersion",
			\controlspec -> r_specs[\PShift][\PitchDispersion],
			\action -> { |value|
				~engine.set_("PitchShift.PitchDispersion", value);
			}
		]
	);

	r_params = r_params.add(
		IdentityDictionary[
			\type -> "control",
			\id -> "time_dispersion",
			\name -> "Time Dispersion",
			\controlspec -> r_specs[\PShift][\TimeDispersion],
			\action -> { |value|
				~engine.set_("PitchShift.TimeDispersion", value);
			}
		]
	);

	r_params = r_params.add(
		IdentityDictionary[
			\type -> "control",
			\id -> "lfo_rate",
			\name -> "LFO Rate",
			\controlspec -> r_specs[\MultiLFO][\Frequency],
			\action -> { |value|
				~engine.set_("LFO.Frequency", value);
			}
		]
	);

	r_params = r_params.add(
		IdentityDictionary[
			\type -> "control",
			\id -> "lfo_to_freq_shift",
			\name -> "LFO > Freq Shift",
			\controlspec -> r_specs[\FShift][\FM],
			\formatter -> formatters[\percentage],
			\action -> { |value|
				~engine.set_("FreqShift.FM", value);
			}
		]
	);

	r_params = r_params.add(
		IdentityDictionary[
			\type -> "control",
			\id -> "lfo_to_pitch_ratio",
			\name -> "LFO > Pitch Ratio",
			\controlspec -> r_specs[\PShift][\PitchRatioModulation],
			\formatter -> formatters[\percentage],
			\action -> { |value|
				~engine.set_("PitchShift.PitchRatioModulation", value);
			}
		]
	);

	r_params;
};

var module = IdentityDictionary[
	\init -> init
];

module
)
