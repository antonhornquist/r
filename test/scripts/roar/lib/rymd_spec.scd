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
	var visual_values = create_visual_values_bufs.value(visual_buf_size);

	init_r_modules.value(engine_global);

	(
		param_specs: get_param_specs.value(engine_global),
		poll_specs: get_poll_specs.value(visual_values),
		visual_values: visual_values
	)
};

var init_r_modules = { |engine_global|
	create_modules.value(engine_global);
	connect_modules.value(engine_global);
	engine_global.pollvisual_(1, "Delay1=DelayTime");
	engine_global.pollvisual_(2, "Delay2=DelayTime");
};

var create_modules = { |engine_global|
	engine_global.new_("LFO", "MultiLFO");
	engine_global.new_("SoundIn", "SoundIn");
	engine_global.new_("Direct", "SGain");
	engine_global.new_("FXSend", "SGain");
	engine_global.new_("Delay1", "Delay");
	engine_global.new_("Delay2", "Delay");
	engine_global.new_("Filter1", "MMFilter");
	engine_global.new_("Filter2", "MMFilter");
	engine_global.new_("Feedback", "SGain");
	engine_global.new_("Amplifier", "SGain");
	engine_global.new_("SoundOut", "SoundOut");
};

var connect_modules = { |engine_global|
	engine_global.connect_("LFO/Sine", "Delay1*DelayTimeModulation");
	engine_global.connect_("LFO/Sine", "Delay2*DelayTimeModulation");
	engine_global.connect_("SoundIn/Left", "Direct*Left");
	engine_global.connect_("SoundIn/Right", "Direct*Right");
	engine_global.connect_("Direct/Left", "Amplifier*Left");
	engine_global.connect_("Direct/Right", "Amplifier*Right");

	engine_global.connect_("SoundIn/Left", "FXSend*Left");
	engine_global.connect_("SoundIn/Right", "FXSend*Right");
	engine_global.connect_("FXSend/Left", "Delay1*In");
	engine_global.connect_("FXSend/Right", "Delay2*In");
	engine_global.connect_("Delay1/Out", "Filter1*In");
	engine_global.connect_("Delay2/Out", "Filter2*In");
	engine_global.connect_("Filter1/Lowpass", "Feedback*Left");
	engine_global.connect_("Filter2/Lowpass", "Feedback*Right");
	engine_global.connect_("Feedback/Left", "Delay2*In");
	engine_global.connect_("Feedback/Right", "Delay1*In");
	engine_global.connect_("Filter1/Lowpass", "Amplifier*Left");
	engine_global.connect_("Filter2/Lowpass", "Amplifier*Right");
	engine_global.connect_("Amplifier/Left", "SoundOut*Left");
	engine_global.connect_("Amplifier/Right", "SoundOut*Right");
};

var create_visual_values_bufs = { |visual_buf_size|
	IdentityDictionary[
		\delay_time_left -> capped_list_create.value(visual_buf_size),
		\delay_time_right -> capped_list_create.value(visual_buf_size)
	];
};

var get_poll_specs = { |visual_values|
	[
		get_delay_time_left_poll_spec.value(visual_values),
		get_delay_time_right_poll_spec.value(visual_values)
	];
};

var get_delay_time_left_poll_spec = { |visual_values|
	var spec = r_specs[\Delay][\DelayTime].copy();

	IdentityDictionary[
		\id -> "delay_time_left",
		\handler -> { |value|
			var visual_value = spec.unmap(value);
			capped_list_push.value(visual_values[\delay_time_left], visual_value);
		}
	];
};

var get_delay_time_right_poll_spec = { |visual_values|
	var spec = r_specs[\Delay][\DelayTime].copy();

	IdentityDictionary[
		\id -> "delay_time_right",
		\handler -> { |value|
			var visual_value = spec.unmap(value);
			capped_list_push.value(visual_values[\delay_time_right], visual_value);
		}
	];
};

var get_param_specs = { |engine_global|
	[
		get_direct_gain_param_spec.value(engine_global),
		get_delay_send_param_spec.value(engine_global),
		get_delay_time_left_param_spec.value(engine_global),
		get_delay_time_right_param_spec.value(engine_global),
		get_damping_param_spec.value(engine_global),
		get_feedback_param_spec.value(engine_global),
		get_mod_rate_param_spec.value(engine_global),
		get_delay_time_mod_depth_param_spec.value(engine_global),
		get_output_level_param_spec.value(engine_global)
	];
};

var get_direct_gain_param_spec = { |engine_global|
	IdentityDictionary[
		\id -> "direct",
		\type -> "control",
		\controlspec -> r_specs[\SGain][\Gain],
		\name -> "Direct",
		\formatter -> custom_formatters[\adaptive_db],
		\narrow_name -> "DIR",
		\action -> { |value|
			engine_global.set_("Direct.Gain", value);
		}
	]
};


var get_delay_send_param_spec = { |engine_global|
	var spec = r_specs[\SGain][\Gain].copy();
	spec.default = -10;

	IdentityDictionary[
		\id -> "delay_send",
		\type -> "control",
		\controlspec -> spec,
		\name -> "Delay Send",
		\formatter -> custom_formatters[\adaptive_db],
		\narrow_name -> "SEND",
		\action -> { |value|
			engine_global.set_("FXSend.Gain", value);
		}
	]
};

var get_delay_time_left_param_spec = { |engine_global|
	var spec = r_specs[\Delay][\DelayTime].copy();
	spec.default = 400;

	IdentityDictionary[
		\id -> "delay_time_left",
		\type -> "control",
		\controlspec -> spec,
		\name -> "Delay Time Left",
		\formatter -> custom_formatters[\adaptive_time],
		\narrow_name -> "L.TIME",
		\action -> { |value|
			engine_global.set_("Delay1.DelayTime", value);
		}
	]
};

var get_delay_time_right_param_spec = { |engine_global|
	var spec = r_specs[\Delay][\DelayTime].copy();
	spec.default = 300;

	IdentityDictionary[
		\id -> "delay_time_right",
		\type -> "control",
		\controlspec -> spec,
		\name -> "Delay Time Right",
		\formatter -> custom_formatters[\adaptive_time],
		\narrow_name -> "R.TIME",
		\action -> { |value|
			engine_global.set_("Delay2.DelayTime", value);
		}
	];
};

var get_damping_param_spec = { |engine_global|
	var spec = r_specs[\MMFilter][\Frequency].copy();
	spec.default = 4000;
	spec.minval = 300;
	spec.maxval = 10000;

	IdentityDictionary[
		\id -> "damping",
		\type -> "control",
		\controlspec -> spec,
		\name -> "Damping",
		\formatter -> custom_formatters[\adaptive_freq],
		\narrow_name -> "DAMP",
		\action -> { |value|
			engine_global.set_("Filter1.Frequency", value);
			engine_global.set_("Filter2.Frequency", value);
		}
	];
};

var get_feedback_param_spec = { |engine_global|
	var spec = r_specs[\SGain][\Gain].copy();
	spec.default = -10;
	spec.maxval = 0;

	IdentityDictionary[
		\id -> "feedback",
		\type -> "control",
		\controlspec -> spec,
		\name -> "Feedback",
		\narrow_name -> "FBK",
		\narrow_formatter -> { |param|
			round(param.get_raw_()*100, 1).asString++"%";
		},
		\action -> { |value|
			engine_global.set_("Feedback.Gain", value);
		}
	];
};

var get_mod_rate_param_spec = { |engine_global|
	IdentityDictionary[
		\id -> "mod_rate",
		\type -> "control",
		\controlspec -> r_specs[\MultiLFO][\Frequency],
		\formatter -> formatters[\round].value(0.001),
		\name -> "Modulation Rate",
		\narrow_name -> "RATE",
		\narrow_formatter -> custom_formatters[\adaptive_spec],
		\action -> { |value|
			engine_global.set_("LFO.Frequency", value);
		}
	];
};

var get_delay_time_mod_depth_param_spec = { |engine_global|
	IdentityDictionary[
		\id -> "delay_time_mod_depth",
		\type -> "control",
		\controlspec -> \unipolar.asSpec,
		\formatter -> formatters[\percentage],
		\name -> "Delay Time Modulation Depth",
		\narrow_name -> "MOD",
		\action -> { |value|
			engine_global.set_("Delay1.DelayTimeModulation", value);
			engine_global.set_("Delay2.DelayTimeModulation", value);
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
