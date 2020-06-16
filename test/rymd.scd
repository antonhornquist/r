(
var include_relative = { |relative_path|
	var path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ relative_path).standardizePath;
	if (File.exists(path)) {
		this.executeFile(path);
	} {
		Error("include_relative: file % does not exist".format(path.quote)).throw;
	};
};

var norns_engine_tester = include_relative.value("../util/norns_engine_tester.scd");
var start_script = norns_engine_tester['start_script'];

start_script.value {
	// scriptname: rymd
	// v1.3.0 @jah
	var r_rymd = include_relative.value('lib/r_rymd.scd');
	var r_rymd_init = r_rymd[\init];

	var formatters = include_relative.value("lib/formatters.scd");

	var common = include_relative.value("lib/common.scd");
	var common_init = common[\init];
	var common_cleanup = common[\cleanup];
	var common_redraw = common[\redraw];
	var common_enc = common[\enc];
	var common_key = common[\key];
	var common_mouse = common[\mouse];

	var settings_file = "rymd.data";
	var fps = 35;

	~engine.name = 'R';

	~init = {
		var r_polls, visual_values, r_params;
		var ui;

		# r_polls, visual_values, r_params = r_rymd_init.value(round(fps/20));

		ui = (
			arc: ( device: ~arc.connect_() ),
			pages: [
				[
					(
						label: "DIR",
						id: "direct",
						formatter: formatters[\adaptive_db],
					),
					(
						label: "SEND",
						id: "delay_send",
						formatter: formatters[\adaptive_db]
					),
				],
				[
					(
						label: "L.TIME",
						id: "delay_time_left",
						formatter: formatters[\adaptive_time],
						visual_values: visual_values[\delay_time_left]
					),
					(
						label: "R.TIME",
						id: "delay_time_right",
						formatter: formatters[\adaptive_time],
						visual_values: visual_values[\delay_time_right]
					),
				],
				[
					(
						label: "DAMP",
						id: "damping",
						formatter: formatters[\adaptive_freq],
					),
					(
						label: "FBK",
						id: "feedback",
						formatter: { |param|
							round(param.get_raw_()*100, 1).asString++"%";
						}
					),
				],
				[
					(
						label: "RATE",
						id: "mod_rate",
						formatter: formatters[\adaptive_freq],
					),
					(
						label: "MOD",
						id: "delay_time_mod_depth",
						formatter: formatters[\percentage],
					),
				],
			]
		);

		common_init.value(r_polls, r_params, ui, settings_file, fps);
	};

	~cleanup = {
		common_cleanup.value(settings_file);
	};

	~redraw = {
		common_redraw.value();
	};

	~enc = { |n, delta|
		common_enc.value(n, delta);
	};

	~key = { |n, z|
		common_key.value(n, z);
	};

	~mouse = { |... args|
		common_mouse.value(*args);
	};
};
)
