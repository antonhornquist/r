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
	var r_moln = include_relative.value('lib/r_moln.scd');
	var r_moln_init = r_moln[\init];
	var r_moln_note_on = r_moln[\note_on];
	var r_moln_note_off = r_moln[\note_off];

	~engine.name = 'R';

	~init = {
		var r_polls, visual_values, r_params;
		var midi_device;

		# r_polls, visual_values, r_params = r_moln_init.value(5);

		r_params.do { |r_param|
			~params.add_(r_param);
		};

		midi_device = ~midi.connect_();
		midi_device.event = { |data|
			var msg = ~midi.to_msg_(data);
			case
			{msg['type'] == 'note_off'} {
				r_moln_note_off.value(msg.note);
			}
			{msg['type'] == 'note_on'} {
				r_moln_note_on.value(msg.note, msg.vel / 127);

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
				r_moln_note_on.value(note, 1);
			} {
				r_moln_note_off.value(note);
			};
		}
		{n == 2} {
			var note = 63;
			if (z == 1) {
				r_moln_note_on.value(note, 1);
			} {
				r_moln_note_off.value(note);
			};
		}
		{n == 3} {
			var note = 67;
			if (z == 1) {
				r_moln_note_on.value(note, 1);
			} {
				r_moln_note_off.value(note);
			};
		}
	};

};
)
