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
	~engine.pollvisual_(1, "Delay1=DelayTime");
	~engine.pollvisual_(2, "Delay2=DelayTime");
};

var create_modules = {
	~engine.new_("LFO", "MultiLFO");
	~engine.new_("SoundIn", "SoundIn");
	~engine.new_("Direct", "SGain");
	~engine.new_("FXSend", "SGain");
	~engine.new_("Delay1", "Delay");
	~engine.new_("Delay2", "Delay");
	~engine.new_("Filter1", "MMFilter");
	~engine.new_("Filter2", "MMFilter");
	~engine.new_("Feedback", "SGain");
	~engine.new_("SoundOut", "SoundOut");
};

var connect_modules = {
	~engine.connect_("LFO/Sine", "Delay1*DelayTimeModulation");
	~engine.connect_("LFO/Sine", "Delay2*DelayTimeModulation");
	~engine.connect_("SoundIn/Left", "Direct*Left");
	~engine.connect_("SoundIn/Right", "Direct*Right");
	~engine.connect_("Direct/Left", "SoundOut*Left");
	~engine.connect_("Direct/Right", "SoundOut*Right");

	~engine.connect_("SoundIn/Left", "FXSend*Left");
	~engine.connect_("SoundIn/Right", "FXSend*Right");
	~engine.connect_("FXSend/Left", "Delay1*In");
	~engine.connect_("FXSend/Right", "Delay2*In");
	~engine.connect_("Delay1/Out", "Filter1*In");
	~engine.connect_("Delay2/Out", "Filter2*In");
	~engine.connect_("Filter1/Lowpass", "Feedback*Left");
	~engine.connect_("Filter2/Lowpass", "Feedback*Right");
	~engine.connect_("Feedback/Left", "Delay2*In");
	~engine.connect_("Feedback/Right", "Delay1*In");
	~engine.connect_("Filter1/Lowpass", "SoundOut*Left");
	~engine.connect_("Filter2/Lowpass", "SoundOut*Right");
};

var init_visual_values_bufs = { |visual_buf_size|
	IdentityDictionary[
		\delay_time_left -> capped_list_create.value(visual_buf_size),
		\delay_time_right -> capped_list_create.value(visual_buf_size)
	];
};

var delay_time_left_spec;
var delay_time_right_spec;

var init_r_polls = {
	[
		IdentityDictionary[
			\id -> "delay_time_left",
			\handler -> { |value|
				var visual_value = delay_time_left_spec.unmap(value);
				capped_list_push.value(visual_values.delay_time_left, visual_value);
			}
		],
		IdentityDictionary[
			\id -> "delay_time_right",
			\handler -> { |value|
				var visual_value = delay_time_right_spec.unmap(value);
				capped_list_push.value(visual_values.delay_time_right, visual_value);
			}
		]
	]
};

var init_r_params = {
	var r_params = [];

	var delay_send_spec;
	var filter_spec;
	var feedback_spec;

	r_params = r_params.add(
		IdentityDictionary[
			\id -> "direct",
			\type -> "control",
			\name -> "Direct",
			\controlspec -> r_specs[\SGain][\Gain],
			\action -> { |value|
				~engine.set_("Direct.Gain", value);
			}
		]
	);

	delay_send_spec = r_specs[\SGain][\Gain].copy();
	delay_send_spec.default = -10;

	r_params = r_params.add(
		IdentityDictionary[
			\id -> "delay_send",
			\type -> "control",
			\name -> "Delay Send",
			\controlspec -> delay_send_spec,
			\action -> { |value|
				~engine.set_("FXSend.Gain", value);
			}
		]
	);

	delay_time_left_spec = r_specs[\Delay][\DelayTime].copy();
	delay_time_left_spec.default = 400;

	r_params = r_params.add(
		IdentityDictionary[
			\id -> "delay_time_left",
			\type -> "control",
			\name -> "Delay Time Left",
			\controlspec -> delay_time_left_spec,
			\action -> { |value|
				~engine.set_("Delay1.DelayTime", value);
			}
		]
	);

	delay_time_right_spec = r_specs[\Delay][\DelayTime].copy();
	delay_time_right_spec.default = 300;

	r_params = r_params.add(
		IdentityDictionary[
			\id -> "delay_time_right",
			\type -> "control",
			\name -> "Delay Time Right",
			\controlspec -> delay_time_right_spec,
			\action -> { |value|
				~engine.set_("Delay2.DelayTime", value);
			}
		]
	);

	filter_spec = r_specs[\MMFilter][\Frequency].copy(); // TODO: damping_spec ?
	filter_spec.default = 4000;
	filter_spec.minval = 300;
	filter_spec.maxval = 10000;

	r_params = r_params.add(
		IdentityDictionary[
			\id -> "damping",
			\type -> "control",
			\name -> "Damping",
			\controlspec -> filter_spec,
			\formatter -> formatters[\percentage],
			\action -> { |value|
				~engine.set_("Filter1.Frequency", value);
				~engine.set_("Filter2.Frequency", value);
			}
		]
	);

	feedback_spec = r_specs[\SGain][\Gain].copy();
	feedback_spec.default = -10;
	feedback_spec.maxval = 0;

	r_params = r_params.add(
		IdentityDictionary[
			\id -> "feedback",
			\type -> "control",
			\name -> "Feedback",
			\controlspec -> feedback_spec,
			\action -> { |value|
				~engine.set_("Feedback.Gain", value);
			}
		]
	);

	r_params = r_params.add(
		IdentityDictionary[
			\id -> "mod_rate",
			\type -> "control",
			\name -> "Mod Rate",
			\controlspec -> r_specs[\MultiLFO][\Frequency],
			\formatter -> formatters[\round].value(0.001),
			\action -> { |value|
				~engine.set_("LFO.Frequency", value);
			}
		]
	);

	r_params = r_params.add(
		IdentityDictionary[
			\id -> "delay_time_mod_depth",
			\type -> "control",
			\name -> "Delay Time Mod Depth",
			\controlspec -> \unipolar.asSpec,
			\formatter -> formatters[\percentage],
			\action -> { |value|
				~engine.set_("Delay1.DelayTimeModulation", value);
				~engine.set_("Delay2.DelayTimeModulation", value);
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
