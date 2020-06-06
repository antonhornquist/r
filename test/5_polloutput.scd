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
	// scriptname: 5_polloutput
	// v1.1.0 @jah
	var formatters = include_relative.value("lib/formatters.scd");
	var r_specs = include_relative.value("lib/r_specs.scd");

	var val;
	var x;

	~engine.name = 'R';

	~init = {
		var screen_y_spec;
		var lfo_sine_output_spec;
		var poll1;

/*
		var screen_refresh_metro;
		var screen_framerate;
		var screen_dirty = false;
*/

		~engine.new_("LFO1", "MultiLFO");
		~engine.new_("LFO2", "MultiLFO");
		~engine.new_("Mixer", "LinMixer");
		~engine.new_("Osc", "PulseOsc");
		~engine.new_("Amplifier", "MGain");
		~engine.new_("SoundOut", "SoundOut");

		~lfo1_shape = 'Sine';
		~lfo2_shape = 'InvSaw';
		~set_lfo_shapes.value;

		~engine.connect_("Mixer/Out", "Osc*FM");
		~engine.connect_("Osc/Out", "Amplifier*In");
		~engine.connect_("Amplifier/Out", "SoundOut*Left");
		~engine.connect_("Amplifier/Out", "SoundOut*Right");

		~engine.set_("LFO2.Frequency", 0.25);
		~engine.set_("Osc.FM", 1);

		~engine.polloutput_(1, "Mixer/Out");

/*
		lfo_to_filter_fm_spec = r_specs['LinMixer']['In1'].copy();
		lfo_to_filter_fm_spec.default = 0.4;

		~params.add_(
			(
				type: "control",
				id: "lfo_to_filter_fm",
				name: "LFO > Filter.FM",
				controlspec: lfo_to_filter_fm_spec,
				formatter: formatters['percentage'],
				action: { |value| ~engine.set_("FilterMod.In1", value) }
			)
		);
*/

		~add_output_level_param.value;
		~params.bang_();

		screen_y_spec = ControlSpec.new(60, 5, 'lin', 1);
		lfo_sine_output_spec = ControlSpec.new(-0.25, 0.25, 'lin');
		val = 0;
		poll1 = ~poll.set_("poll1") { |value|
			val = screen_y_spec.map(lfo_sine_output_spec.unmap(value));
			~redraw.value();
		};
		poll1.time_ = 1/25;
		poll1.start_();

/*
	TODO: not used atm
		screen_refresh_metro = ~metro.init_();
		screen_refresh_metro.event = {
			if (screen_dirty) {
				screen_dirty = false;
				~redraw.value();
			};
		};

		screen_framerate = 15;
		screen_refresh_metro.start_(1 / screen_framerate);
*/
	};

	~add_output_level_param = {
		var spec = r_specs['MGain']['Gain'].copy;
		spec.default = -10;

		~params.add_(
			(
				type: "control",
				id: "output_level",
				name: "Amplifier.Gain",
				controlspec: spec,
				formatter: formatters.round_(0.1),
				action: { |value| ~engine.set_("Amplifier.Gain", value) }
			)
		);
	};

	~reset_lfo_shapes = { |lfo1_shape, lfo2_shape|
		~engine.disconnect_("LFO1/"++~lfo1_shape.asString, "Mixer*In1");
		~engine.disconnect_("LFO2/"++~lfo2_shape.asString, "Mixer*In2");
		~lfo1_shape = lfo1_shape;
		~lfo2_shape = lfo2_shape;
		~set_lfo_shapes.value;
	};

	~set_lfo_shapes = {
		~engine.connect_("LFO1/"++~lfo1_shape.asString, "Mixer*In1");
		~engine.connect_("LFO2/"++~lfo2_shape.asString, "Mixer*In2");
	};

	~redraw = {
		~screen.clear_();
		case
		{x.isNil} {
			x = 1;
		}
		{x > 128} {
			x = 1;
		}
		{true} {
			x = x + 1;
		};
		~screen.rect_(x, val, 2, 2);
		~screen.fill_();
		~screen.level_(15);
		~screen.move_(1, 10);
		~screen.text_("POLLOUTPUT");
		~screen.move_(1, 30);
		// ~screen.text_("See params in menu");
		~screen.update_();
	};

	~enc = { |n, delta|
		case
		{n == 1} {
			~params.delta_("output_level", delta);
		};
	};

	~key = { |n, z|
		if (n == 3) {
			case
			{z == 1} {
				~engine.set_("LFO1.Frequency", 3.rand);
				~engine.set_("LFO2.Frequency", 3.rand);
				~reset_lfo_shapes.value(['InvSaw', 'Saw', 'Sine', 'Triangle', 'Pulse'].choose, ['InvSaw', 'Saw', 'Sine', 'Triangle', 'Pulse'].choose);
			};
		};
	};
};
)
