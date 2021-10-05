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

start_script.value {
	var skev_spec = include_relative.value('lib/skev_spec.scd');
	var skev_spec_init = skev_spec[\init];

	var add_params = { |param_specs|
		param_specs.do { |param_spec|
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
	};

	~engine.name = 'R';

	~init = {
		var spec = skev_spec_init.value(
			(
				engine_global: ~engine,
				visual_buf_size: round(ui_refresh_rate/20)
			)
		);

		common_add_params.value(spec[\param_specs], ~params);

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
