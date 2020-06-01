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
	// scriptname: skev
	// v1.3.0 @jah
	var r_skev = include_relative.value('lib/r_skev.scd');
	var r_skev_init = r_skev[\init];

	var formatters = include_relative.value("lib/formatters.scd");

	var common = include_relative.value("lib/common.scd");
	var common_init = common[\init];
	var common_cleanup = common[\cleanup];
	var common_redraw = common[\redraw];
	var common_enc = common[\enc];
	var common_key = common[\key];

	var settings_file = "skev.data";
	var fps = 35;

	~engine.name = 'R';

	~init = {
		var r_polls, visual_values, r_params;
		var ui;

		# r_polls, visual_values, r_params = r_skev_init.value(round(fps/20));

		ui = (
			arc: ( device: ~arc.connect_() ),
			pages: [
				[
					(
						label: "F.SHFT",
						id: "freq_shift",
						formatter: formatters[\adaptive_freq],
						visual_values: visual_values[\freq_shift]
					),
					(
						label: "P.RAT",
						id: "pitch_ratio",
						formatter: formatters[\percentage],
						visual_values: visual_values[\pitch_ratio]
					),
				],
				[
					(
						label: "P.DISP",
						id: "pitch_dispersion",
						formatter: formatters[\percentage]
					),
					(
						label: "T.DISP",
						id: "time_dispersion",
						formatter: formatters[\percentage]
					),
				],
				[
					(
						label: "LFO.HZ",
						id: "lfo_rate",
						formatter: formatters[\adaptive_freq],
					),
					(
						label: "LFO.SHP",
						id: "lfo_rate",
						formatter: { |param|
							"N/A";
						}
					),
				],
				[
					(
						label: ">F.SHIFT",
						id: "lfo_to_freq_shift",
						formatter: formatters[\percentage],
					),
					(
						label: ">P.RAT",
						id: "lfo_to_pitch_ratio",
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
};
)
