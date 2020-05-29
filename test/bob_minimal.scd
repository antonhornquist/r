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
	var r_bob = include_relative.value('lib/r_bob.scd');
	var r_bob_init = r_bob[\init];

	~engine.name = 'R';

	~init = {
		var r_polls, visual_values, r_params;
		# r_polls, visual_values, r_params = r_bob_init.value(5);

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
		~screen.text_("BOB (MINIMAL)");
		~screen.update_();
	};

	~enc = { |n, delta|
		case
		{n == 2} {
			~params.delta_("cutoff", delta);
		}
		{n == 3} {
			~params.delta_("resonance", delta);
		};
	};

	~key = { |n, z|
	};
};
)
