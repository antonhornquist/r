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

	var r_snd_init = r_snd[\init]; // TODO: arguments: config = dict, returns instance = dict

	var common = include_relative.value("lib/common.scd");
	var common_init = common[\init];
	var common_redraw = common[\redraw];
	var common_key = common[\key];
	var common_mouse = common[\mouse];

	var settings_file = "snd.data";
	var ui_refresh_rate = 35;

	var script_context;

	~engine.name = 'R';

	~init = {
		var r_snd_instance = r_snd_init.value(
			(
				engine_global: ~engine, // TODO: call this key engine_global?
				visual_buf_size: round(ui_refresh_rate/20)
			)
		);

		var ui_spec = (
			pages: [
				[ ( id: 'frequency' ), ( id: 'pulse_width' ) ],
				[ ( id: 'cutoff' ), ( id: 'resonance' ) ]
			],
			refresh_rate: ui_refresh_rate // TODO: call this refresh_rate instead?
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
				param_specs: r_snd_instance[\param_specs],
				ui_spec: ui_spec,
				settings_file: settings_file,
			)
		);
	};

	~redraw = {
		common_redraw.value(script_context);
	};

	~key = { |n, z|
		common_key.value(script_context, n, z);
	};

	~mouse = { |... args| // TODO: get away from using varargs for ~mouse
		common_mouse.value(*([script_context]++args)); // TODO: get away from using varargs for ~mouse
	};
};
)
