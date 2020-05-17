(
var include_relative = { |relative_path|
	var path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ relative_path).standardizePath;
	this.executeFile(path);
};

var norns_engine_tester = include_relative.value("../util/norns_engine_tester.scd");
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
			msg.debug(\msg);
			case
			{msg['type'] == 'note_off'} {
				[msg.note].debug('off');
				r_moln_note_off.value(msg.note);
			}
			{msg['type'] == 'note_on'} {
				[msg.note, msg.vel / 127].debug('on');
				r_moln_note_on.value(msg.note, msg.vel / 127);

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