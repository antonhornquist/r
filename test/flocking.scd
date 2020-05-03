(
var include = { |relative_path|
	var path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ relative_path).standardizePath;
	this.executeFile(path);
};

var nel = include.value("../util/nel.scd");
var start_script = nel['start_script'];

start_script.value(nil) {
	var width = 128*2;
	var height = 64*2;

	var vector3d_new = { |x_, y_, z_|
		var vector = ();
		vector.x_ = x_ ? 0;
		vector.y_ = y_ ? 0;
		vector.z_ = z_ ? 0;
		vector.set_xyz_ = { |self, x_, y_, z_|
			self.x_ = x_;
			self.y_ = y_;
			self.z_ = z_;
		};
		vector.magnitude_ = { |self|
			sqrt((self.x_*self.x_) + (self.y_*self.y_) + (self.z_*self.z_));
		};
		vector.add_ = { |self, vector|
			var func_name = 'vector.add_';
			self.x_ = self.x_ + vector.x_;
			self.y_ = self.y_ + vector.y_;
			self.z_ = self.z_ + vector.z_;
		};
		vector.mult_ = { |self, n|
			var func_name = 'vector.mult_';
			self.x_ = self.x_ * n;
			self.y_ = self.y_ * n;
			self.z_ = self.z_ * n;
		};
		vector.div_ = { |self, n|
			var func_name = 'vector.div_';
			self.x_ = self.x_ / n;
			self.y_ = self.y_ / n;
			self.z_ = self.z_ / n;
		};
		vector.normalize_ = { |self|
			var func_name = 'vector.normalize_';
			var magnitude = self.magnitude_();
			if (magnitude > 0) {
				self.div_(magnitude);
			};
		};
		vector.limit_ = { |self, max|
			var func_name = 'vector.limit_';
			if (self.magnitude_() > max) {
				self.normalize_();
				self.mult_(max);
			};
		};
		vector;
	};

	var vector3d_sub = { |vector1, vector2|
		var func = 'vector3d_sub';
		vector3d_new.value(vector1.x_-vector2.x_, vector1.y_-vector2.y_, vector1.z_-vector2.z_);
	};

	var vector3d_distance = { |vector1, vector2|
		var func = 'vector3d_distance';
		var dx = vector1.x_ - vector2.x_;
		var dy = vector1.y_ - vector2.y_;
		var dz = vector1.z_ - vector2.z_;
		sqrt(dx*dx + dy*dy + dz*dz);
	};

	var boid_new = { |l, ms, mf|
		var boid = ();
		var velx;
		var vely;
		boid.acc_ = vector3d_new.value(0, 0);
		velx = (1.0.rand * 2) - 1;
		vely = (1.0.rand * 2) - 1;
		boid.vel_ = vector3d_new.value(velx, vely);
		boid.loc_ = l.copy();
		boid.r_ = 2.0;
		boid.maxspeed_ = ms; // Maximum speed
		boid.maxforce_ = mf; // Maximum steering force
		// boid.left_edge = { };
		// boid.right_edge = { };
		// boid.top_edge = { };
		// boid.bottom_edge = { };
		boid.run_ = { |self, boids|
			self.flock_(boids);
			self.update_();
			self.borders_();
		};
		// We accumulate a new acceleration each time based on three rules
		boid.flock_ = { |self, boids|
			var func_name = 'boid.flock_';
			var sep = self.separate_(boids);
			var ali = self.align_(boids);
			var coh = self.cohesion_(boids);

			// Arbitrarily weight these forces
			//sep:mult(2)
			//ali:mult(1)
			//coh:mult(1)
			sep.mult_(~params.get_('sep'));
			ali.mult_(~params.get_('ali'));
			coh.mult_(~params.get_('coh'));

			// Add the force vectors to acceleration
			self.acc_.add_(sep);
			self.acc_.add_(ali);
			self.acc_.add_(coh);
		};
		// Method to update location
		boid.update_ = { |self|
			// Update velocity
			self.vel_.add_(self.acc_);

			// Limit speed
			self.vel_.limit_(self.maxspeed_);
			self.loc_.add_(self.vel_);

			// Reset accelertion to 0 each cycle
			self.acc_.set_xyz_(0, 0, 0);
		};
		boid.seek_ = { |self, target|
			self.acc_.add_(self.steer_(target, false));
		};
		boid.arrive_ = { |self, target|
			self.acc_.add_(self.steer_(target, true));
		};
		// A method that calculates a steering vector towards a target
		// Takes a second argument, if true, it slows down as it approaches the target
		boid.steer_ = { |self, target, slowdown|
			var steer;
			var desired = vector3d_sub.value(target, self.loc_); // A vector pointing from the location to the target
			var distance = desired.magnitude_(); // Distance from the target is the magnitude of the vector

			// If the distance is greater than 0, calc steering (otherwise return zero vector)
			if (distance > 0) {
				// Normalize desired
				desired.normalize_();

				// Two options for desired vector magnitude (1 -- based on distance, 2 -- maxspeed)
				if (slowdown and: (distance < 100)) {
					desired.mult_(self.maxspeed_*(distance/100)); // This damping is somewhat arbitrary
				} {
					desired.mult_(self.maxspeed_);
				};

				// Steering = Desired minus Velocity
				steer = vector3d_sub.value(desired, self.vel);
				steer.limit_(self.maxforce_) // Limit to maximum steering force
			} {
				steer = vector3d_new.value(0, 0);
			};
			steer;
		};
		// Wraparound
		boid.borders_ = { |self|
			var loc = self.loc_;
			var r_ = self.r_;
			if (loc.x_ < r_.neg) {
				loc.x_ = width + r_;
				// TODO self.left_edge(self);
			};

			if (loc.y_ < r_.neg) {
				loc.y_ = height + r_;
				// TODO self.top_edge(self);
			};

			if (loc.x_ > (width+r_)) {
				loc.x_ = r_.neg;
				// TODO self.right_edge(self);
			};

			if (loc.y_ > (height+r_)) {
				loc.y_ = r_.neg;
				// TODO self.bottom_edge(self);
			};
		};
		// Separation
		// Method checks for nearby boids and steers away
		boid.separate_ = { |self, boids|
			var func_name = 'boid.separate_';
			var desiredseparation  = 25.0;
			var sum = vector3d_new.value(0, 0, 0);
			var count = 0;

			// For every boid in the system, check if it's too close
			boids.do { |boid|
				var other = boid;
				var distance = vector3d_distance.value(self.loc_, other.loc_);

				// If the distance is greater than 0 and less than an arbitrary amount (0 when you are yourself)
				if ((distance > 0) and: (distance < desiredseparation)) {
					// Calculate vector pointing away from neighbor
					var diff = vector3d_sub.value(self.loc_, other.loc_);

					diff.normalize_();
					diff.div_(distance); //Weight by distance
					sum.add_(diff);
					count = count + 1; // Keep track of how many
				};
			};

			// Average -- divide by how many
			if (count > 0) {
				sum.div_(count);
			};
			sum;
		};
		// Alignment
		// For every nearby boid in the system, calculate the average velocity
		boid.align_ = { |self, boids|
			var neighbordist = 50.0;

			var sum = vector3d_new.value(0, 0, 0);

			var count = 0;

			boids.do { |boid|
				var other = boid;
				var distance = vector3d_distance.value(self.loc_, other.loc_);

				if ((distance > 0) and: (distance < neighbordist)) {
					sum.add_(other.vel_);
					count = count + 1;
				};
			};

			if (count > 0) {
				sum.div_(count);
				sum.limit_(self.maxforce_);
			};

			sum;
		};
		// Cohesion
		// For the average location (i.e. center) of all nearby boids, calculate steering vector towards that location
		boid.cohesion_ = { |self, boids|
			var neighbordist = 50.0;
			var sum = vector3d_new.value(0, 0, 0); // Start with empty vector to accumulate all locations
			var count = 0;

			boids.do { |boid|
				var other = boid;
				var dist = vector3d_distance.value(self.loc_, other.loc_);

				if ((dist > 0) and: (dist < neighbordist)) {
					sum.add_(other.loc_); // Add location
					count = count + 1;
				};
			};

			if (count > 0) {
				sum.div_(count);
				self.steer_(sum, false); // Steer towards the location
			} {
				sum;
			}
		};
		boid;
	};

	var flock_new = {
		var flock = ();
		flock.run_ = { |self|
			self.boids_.do { |boid|
				boid.run_(self.boids_);
			};
		};
		flock.add_boid_ = { |self, boid|
			self.boids_ = self.boids_.add(boid);
		};
		flock.boids_ = [];
		flock
	};

	var flock;

	var respawn = {
		flock = flock_new.value();

		~flock = flock;

		~params.get_('boids').do {
			var boid = boid_new.value(vector3d_new.value(width/2, height/2), 1.0, 0.05);
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
				controlspec: ControlSpec(5, 25, default: 15),
			)
		);

		~params.add_(
			(
				type: 'control',
				id: 'sep',
				name: "sep",
				controlspec: ControlSpec(1, 10, default: 2),
			)
		);

		~params.add_(
			(
				type: 'control',
				id: 'ali',
				name: "ali",
				controlspec: ControlSpec(1, 10, default: 1),
			)
		);

		~params.add_(
			(
				type: 'control',
				id: 'coh',
				name: "coh",
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
			~mix.delta_('output', delta);
			~redraw.value();
		}
		{n == 2} {
			~params.delta_('sep', delta);
			~redraw.value();
		}
		{ n == 3 } {
			~params.delta_('ali', delta);
			~redraw.value();
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
/*
			~screen.move_(x_, y_);
			~screen.line_rel_(rel_x_, rel_y_);
			~screen.stroke();
*/
		};

		~screen.update_();
	};

	~cleanup = {
		"cleanup".debug;
	};
};
)
