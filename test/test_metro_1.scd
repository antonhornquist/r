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
	~init = {
		var screen_refresh_metro;
/*
		var arc_device = ~arc.connect_();
		var grid_device = ~grid.connect_();

		arc_device.led_(1, 1, 15);
		grid_device.led_(1, 1, 15);
*/
		~screen_dirty = false;
		~framerate = 60;

		screen_refresh_metro = ~metro.init_();
		screen_refresh_metro[\event] = {
/*
			if (~screen_dirty) {
				~screen_dirty = false;
				~redraw.value;
			};
*/
			~redraw.value;
		};
		screen_refresh_metro.start_(1 / ~framerate);
	};

	~redraw = {
		if ([true, false, false, false].choose) {
			~screen.clear_();
		};
		~screen.level_(15);
		~screen.rect_(1, 1, 1, 1);
		~screen.move_(128.rand+1, 64.rand+1);
		~screen.line_(128.rand+1, 64.rand+1);
		~screen.stroke_();
		~screen.update_();
	};

	~cleanup = {
		"cleanup".debug;
	};
};
)
