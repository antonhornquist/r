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
	var boids = include_relative.value("lib/boids.scd");
	var flock_new = boids[\flock_new];
	var boid_new = boids[\boid_new];
	var vector3d_new = boids[\vector3d_new];

	var width = 128*2;
	var height = 64*2;

	var flock;

	var respawn = {
		flock = flock_new.value(width, height);

		~flock = flock;

		~params.get_('boids').do {
			//var boid = boid_new.value(vector3d_new.value(width/2, height/2), 1.0, 0.05);
			// var boid = boid_new.value(vector3d_new.value(width.rand, height.rand), 1.0, 0.05);
			var boid = boid_new.value(vector3d_new.value(width.rand, height.rand), 3.0, 0.1, width, height);
/*
			boid.left_edge = function(b)
				engine.hz(to_hz(notes[rand]))
			end
			boid.right_edge = function(b)
				engine.hz(to_hz(notes[rand]+12))
			end
			boid.bottom_edge = function(b)
				engine.hz(to_hz(notes[rand]-12))
			end
			boid.top_edge = function(b)
				engine.hz(to_hz(notes[rand]+24))
			end
*/
			flock.add_boid_(boid);
		};
	};

	~init = {
		~timer = ~metro.init_();
		~timer.event = {
			flock.run_();
			~redraw.value();
		};

		~params.add_(
			(
				type: 'control',
				id: 'boids',
				name: "boids",
				controlspec: ControlSpec(5, 25, default: 10),
			)
		);

		~params.add_(
			(
				type: 'control',
				id: 'sep',
				name: "separation", // steer to avoid crowding local flockmates
				controlspec: ControlSpec(1, 10, default: 2),
			)
		);

		~params.add_(
			(
				type: 'control',
				id: 'ali',
				name: "alignment", // steer towards the average heading of local flockmates
				controlspec: ControlSpec(1, 10, default: 1),
			)
		);

		~params.add_(
			(
				type: 'control',
				id: 'coh',
				name: "cohesion", // steer to move towards the average position (center of mass) of local flockmates
				controlspec: ControlSpec(1, 10, default: 1),
			)
		);

		~params.add_(
			(
				type: 'control',
				id: 'run',
				name: "run",
				controlspec: ControlSpec(0, 1, step: 1, default: 0),
				action: { |value|
					if (value == 0) {
						~timer.start_();
					} {
						~timer.stop_();
					};
				}
			)
		);

		~params.add_(
			(
				type: 'control',
				id: 'fps',
				name: "fps",
				controlspec: ControlSpec(0, 120, default: 60),
				action: { |value|
					~timer.time = 1/value;
				}
			)
		);

		respawn.value();

		~params.bang_();

		"init".debug;
	};

	~enc = { |n, delta|
		//["enc" + n + delta].debug;
		case
		{n == 1} {
			~params.delta_('coh', delta);
			postln(~params.string_('coh'));
		}
		{n == 2} {
			~params.delta_('sep', delta);
			postln(~params.string_('sep'));
		}
		{ n == 3 } {
			~params.delta_('ali', delta);
			postln(~params.string_('ali'));
		};
	};

	~key = { |n, z|
		//["key" + n + z].debug;
		if ((n == 3) and: (z == 1)) {
			respawn.value();
		};
	};

	~redraw = {
		~screen.clear_();
		~screen.font_size_(8);
		~screen.level_(15);
		~screen.move_(1, 8);
		~screen.text_("flocking");

		flock.boids_.do { |boid|
			var x_ = round(boid.loc_.x_/2);
			var y_ = round(boid.loc_.y_/2);
			var rel_x_ = round(boid.vel_.x_*1.25);
			var rel_y_ = round(boid.vel_.y_*1.25);
			~screen.rect_(x_, y_, 1, 1);
			~screen.fill_();
			~screen.move_(x_, y_);
			~screen.line_rel_(rel_x_, rel_y_); // TODO: looks funny when pixels are large, fix by offsetting
			~screen.stroke_();
		};

		~screen.update_();
	};

	~cleanup = {
		"cleanup".debug;
	};
};
)
