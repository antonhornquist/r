(
var include_relative = { |relative_path|
	var path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ relative_path).standardizePath;
	if (File.exists(path)) {
		this.executeFile(path);
	} {
		Error("include_relative: file % does not exist".format(path.quote)).throw;
	};
};

var norns_engine_tester = include_relative.value("../../util/norns_engine_tester.scd");
var start_script = norns_engine_tester['start_script'];

start_script.value {
	var r_skev = include_relative.value('lib/r_skev.scd');
	var r_skev_init = r_skev[\init];

	~engine.name = 'R';

	~init = {
		var r_polls, visual_values, r_params;
		# r_polls, visual_values, r_params = r_skev_init.value(5);

		r_params.do { |r_param|
			~params.add_(r_param);
		};

		~params.bang_();
	};

	~cleanup = {
	};

	~redraw = {
		~screen.clear_();
		~screen.level_(15);
		~screen.move_(1, 10);
		~screen.text_("SKEV (MINIMAL)");
		~screen.update_();
	};

	~enc = { |n, delta|
		case
		{n == 1} {
			~params.delta_("pitch_ratio", delta);
		}
		{n == 2} {
			~params.delta_("pitch_dispersion", delta);
		}
		{n == 3} {
			~params.delta_("time_dispersion", delta);
		};
	};

	~key = { |n, z|
	};
};
)
