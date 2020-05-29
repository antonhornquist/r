(
var include_relative = { |relative_path|
	var path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ relative_path).standardizePath;
	this.executeFile(path);
};

var norns_engine_tester = include_relative.value("../util/norns_engine_tester.scd");
var start_script = norns_engine_tester['start_script'];

start_script.value {
	// scriptname: bob
	// v1.3.0 @jah
	var r_bob = include_relative.value('lib/r_bob.scd');
	var r_bob_init = r_bob[\init];

	var formatters = include_relative.value("lib/formatters.scd");

	var common = include_relative.value("lib/common.scd");
	var common_init = common[\init];
	var common_cleanup = common[\cleanup];
	var common_redraw = common[\redraw];
	var common_enc = common[\enc];
	var common_key = common[\key];

	var settings_file = "bob.data";
	var fps = 35;

	~engine.name = 'R';

	~init = {
		var r_polls, visual_values, r_params;
		var ui;

		# r_polls, visual_values, r_params = r_bob_init.value(round(~fps/20));

		ui = (
			arc: ( device: ~arc.connect_() ),
			pages: [
				[
					(
						label: "CUTOFF",
						id: "cutoff",
						formatter: formatters[\adaptive_freq],
						visual_values: visual_values[\cutoff]
					),
					(
						label: "RES",
						id: "resonance",
						formatter: formatters[\percentage]
					),
				],
				[
					(
						label: "LFO",
						id: "lfo_rate",
						formatter: formatters[\adaptive_freq],
					),
					(
						label: "L>FRQ",
						id: "lfo_to_cutoff",
						formatter: formatters[\percentage]
					),
				],
				[
					(
						label: "E.ATK",
						id: "envf_attack",
						formatter: formatters[\adaptive_time],
					),
					(
						label: "E.DEC",
						id: "envf_decay",
						formatter: formatters[\adaptive_time],
					),
				],
				[
					(
						label: "E.SNS",
						id: "envf_sensivity",
						formatter: formatters[\percentage],
					),
					(
						label: "E>FRQ",
						id: "env_to_cutoff",
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
