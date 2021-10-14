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

var norns_engine_tester = include_relative.value("../util/norns_engine_tester.scd");
var start_script = norns_engine_tester['start_script'];

start_script.value {
	// scriptname: 1_square
	// v1.1.0 @jah
	var formatters = include_relative.value("lib/formatters.scd");
	var r_specs = include_relative.value("lib/r_specs.scd");

	~engine.name = 'R';

	~init = {
	};

	~redraw = {
		~screen.clear_();
		~screen.level_(15);
		~screen.move_(1, 10);
		~screen.text_("MOUSE");
		if (~mouse_from_pos.notNil and: ~mouse_to_pos.notNil) {
			~screen.move_(~mouse_from_pos.x, ~mouse_from_pos.y);
			~screen.line_(~mouse_to_pos.x, ~mouse_to_pos.y);
			~screen.stroke_();
		};
		~screen.update_();
	};

	~enc = { |n, delta|
	};

	~mouse = { |what ... args|
		[what, args].debug;
		case
/*
		{ what == "over" } {
			~mouse_over_pos = x@y;
			~redraw.value();
		}
*/
		{ what == "down" } {
			var x = args[0], y = args[1];
			~mouse_from_pos = x@y;
			~mouse_to_pos = x@y;
			~redraw.value();
		}
		{ what == "move" } {
			var x = args[0], y = args[1];
			~mouse_to_pos = x@y;
			~redraw.value();
		}
		{ what == "up" } {
			~mouse_from_pos = nil;
			~mouse_to_pos = nil;
			~redraw.value();
		}
	};
};
)


