

(
var include_relative = { |relative_path|
	var path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ relative_path).standardizePath;
	if (File.exists(path)) {
		var result = this.executeFile(path);
		if (result.isNil) { Error("error importing %".format(path)).throw; } { result }; // TODO: adopt in other places too
	} {
		Error("include_relative: file % does not exist".format(path.quote)).throw;
	};
};

var norns_engine_tester = include_relative.value("../../util/norns_engine_tester.scd");
var start_script = norns_engine_tester['start_script'];
var script_name = PathName(thisProcess.nowExecutingPath).fileNameWithoutExtension;

start_script.value(script_name) {
	// scriptname: bob_minimal
	// v1.3.0 @jah
	var bob_spec = include_relative.value('lib/bob_spec.scd');
	var bob_spec_init = bob_spec[\init];

	~engine.name = 'R';

	~init = {
		var spec = bob_spec_init.value(
			(
				engine_global: ~engine,
				visual_buf_size: 0
			)
		);

		spec[\param_specs].do { |param_spec|
			~params.add_(
				(
					type: param_spec[\type],
					id: param_spec[\id],
					name: param_spec[\narrow_name] ? param_spec[\name],
					controlspec: param_spec[\controlspec],
					formatter: param_spec[\narrow_formatter] ? param_spec[\formatter],
					action: { |value|
						param_spec[\action].value(value);
					}
				)
			);
		};

		~params.read_();
		~params.bang_();
	};

	~cleanup = {
		~params.write_();
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
