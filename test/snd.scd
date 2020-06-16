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
	var r_snd = include_relative.value('lib/r_snd.scd');
	var r_snd_init = r_snd[\init];

	var formatters = include_relative.value("lib/formatters.scd");

	var common = include_relative.value("lib/common.scd");
	var common_init = common[\init];
	var common_redraw = common[\redraw];
	var common_key = common[\key];
	var common_mouse = common[\mouse];

	var settings_file = "snd.data";
	var fps = 35;

	~engine.name = 'R';

	~init = {
		var r_polls, visual_values, r_params;
		var ui;

		# r_polls, visual_values, r_params = r_snd_init.value(round(fps/20));

		ui = (
			pages: [
				[
					(
						label: "FREQ",
						id: "frequency",
						formatter: formatters[\adaptive_freq]
					),
					(
						label: "PW",
						id: "pulse_width",
						formatter: formatters[\percentage]
					),
				],
				[
					(
						label: "CUTOFF",
						id: "cutoff",
						formatter: formatters[\adaptive_freq],
					),
					(
						label: "RES",
						id: "resonance",
						formatter: formatters[\percentage]
					),
				],
			]
		);

		common_init.value(r_polls, r_params, ui, settings_file, fps);
	};

	~redraw = {
		common_redraw.value();
	};

	~key = { |n, z|
		common_key.value(n, z);
	};

	~mouse = { |... args|
		common_mouse.value(*args);
	};
};
)
