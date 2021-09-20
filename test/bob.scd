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
	// scriptname: bob
	// v1.3.0 @jah
	var bob_spec = include_relative.value('lib/bob_spec.scd');
	var bob_spec_init = bob_spec[\init];

	var common = include_relative.value("lib/common.scd");
	var common_init = common[\init];
	var common_redraw = common[\redraw];
	var common_key = common[\key];
	var common_mouse = common[\mouse];

	var settings_file = "bob.data";
	var ui_refresh_rate = 35;

	var script_context;

	~engine.name = 'R';

	~init = {
		var bob_spec_instance = bob_spec_init.value(
			(
				engine_global: ~engine,
				visual_buf_size: round(ui_refresh_rate/20)
			)
		);

		var ui_spec = (
			arc_device: ~arc.connect_(),
			pages: [
				[ (id: 'cutoff'), (id: 'resonance') ],
				[ (id: 'lfo_rate'), (id: 'lfo_to_cutoff') ],
				[ (id: 'envf_attack'), (id: 'envf_decay') ],
				[ (id: 'envf_sensitivity'), ( id: 'env_to_cutoff') ],
			],
			refresh_rate: ui_refresh_rate
		);

		script_context = common_init.value(
			(
				globals: (
					screen: ~screen,
					metro: ~metro,
					params: ~params,
					poll: ~poll,
					redraw: ~redraw
				),
				param_specs: bob_spec_instance[\param_specs],
				poll_specs: bob_spec_instance[\poll_specs],
				visual_values: bob_spec_instance[\visual_values],
				ui_spec: ui_spec,
				settings_file: settings_file,
			)
		);
	};

/*
	TODO
	~cleanup = {
		common_cleanup.value(settings_file);
	};
*/

	~redraw = {
		common_redraw.value(script_context);
	};

/*
	TODO
	~enc = { |n, delta|
		common_enc.value(n, delta);
	};
*/

	~key = { |n, z|
		common_key.value(script_context, n, z);
	};

	~mouse = { |... args| // TODO: get away from using varargs for ~mouse
		common_mouse.value(*([script_context]++args)); // TODO: get away from using varargs for ~mouse
	};
};
)
