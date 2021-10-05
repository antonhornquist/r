(
var include_relative = { |relative_path|
	var path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ relative_path).standardizePath;
	this.executeFile(path);
};

var norns_engine_tester = include_relative.value("../../util/norns_engine_tester.scd");
var start_script = norns_engine_tester['start_script'];

start_script.value {
	var r_rymd = include_relative.value('lib/r_rymd.scd');
	var r_rymd_init = r_rymd[\init];

	~engine.name = 'R';

	~init = {
		var r_polls, visual_values, r_params;
		# r_polls, visual_values, r_params = r_rymd_init.value(5);

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
		~screen.text_("RYMD (MINIMAL)");
		~screen.update_();
	};

	~enc = { |n, delta|
		case
		{n == 1} {
			~params.delta_("feedback", delta);
		}
		{n == 2} {
			~params.delta_("delay_time_left", delta);
		}
		{n == 3} {
			~params.delta_("delay_time_right", delta);
		};
	};

	~key = { |n, z|
	};
};
)
