(
var nel_path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ "../util/norns_engine_tester.scd").standardizePath;
var norns_engine_tester = this.executeFile(nel_path);

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
