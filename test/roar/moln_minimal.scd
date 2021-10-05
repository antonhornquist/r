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
	var moln_spec = include_relative.value('lib/moln_spec.scd');
	var moln_spec_init = moln_spec[\init];
	var moln_spec_note_on = moln_spec[\note_on];
	var moln_spec_note_off = moln_spec[\note_off];

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

	var init_midi = {
		var midi_device;

		midi_device = ~midi.connect_();
		midi_device.event = { |data|
			var msg = ~midi.to_msg_(data);
			case
			{msg['type'] == 'note_off'} {
				moln_spec_note_off.value(~engine, msg.note);
			}
			{msg['type'] == 'note_on'} {
				moln_spec_note_on.value(~engine, msg.note, msg.vel / 127);

			}
			{msg['type'] == 'cc'} {
				var num = msg['num'];
				var val = msg['val'];
				var delta = if (val > 64, val-128, val);
				case
				{num == 1} {
					~params.delta_( "lfo_frequency", delta);
				}
				{num == 2} {
					~params.delta_( "lfo_to_osc_pwm", delta);
					~params.delta_( "osc_detune", delta);
				}
				{num == 3} {
					~params.delta_( "filter_frequency", delta);
				}
				{num == 4} {
					~params.delta_( "env_release", delta);
				}
			}
		};

	};

	~engine.name = 'R';

	~init = {
		var spec = moln_spec_init.value(
			(
				engine_global: ~engine,
				visual_buf_size: 0
			)
		);

		init_midi.value();

		add_params.value(spec[\param_specs]);

		~params.bang_();
	};

	~cleanup = {
	};

	~redraw = {
		~screen.clear_();
		~screen.level_(15);
		~screen.move_(1, 10);
		~screen.text_("MOLN (MINIMAL)");
		~screen.update_();
	};

	~enc = { |n, delta|
		case
		{n == 1} {
			~params.delta_("osc_a_range", delta);
		}
		{n == 2} {
			~params.delta_("osc_detune", delta);
		}
		{n == 3} {
			~params.delta_("filter_frequency", delta);
		};
	};

	~key = { |n, z|
		case
		{n == 1} {
			var note = 60;
			if (z == 1) {
				moln_spec_note_on.value(~engine, note, 1);
			} {
				moln_spec_note_off.value(~engine, note);
			};
		}
		{n == 2} {
			var note = 63;
			if (z == 1) {
				moln_spec_note_on.value(~engine, note, 1);
			} {
				moln_spec_note_off.value(~engine, note);
			};
		}
		{n == 3} {
			var note = 67;
			if (z == 1) {
				moln_spec_note_on.value(~engine, note, 1);
			} {
				moln_spec_note_off.value(~engine, note);
			};
		}
	};
};
)
