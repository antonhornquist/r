(
var init_metro = {
	var metros = [];

	var metro = ();

	metro.init_ = { |self, config|
		var event = config !? _.event;
		var time = (config !? _.time) ? 1;
		var count = (config !? _.count) ? inf;

		metro = ();
		metro[\event] = event;
		metro[\time] = time;
		metro[\count] = count;
		metro[\id] = metros.size;
		metro[\is_running] = false;
		metro.start_ = { |self, time, count|
			if (time.notNil) {
				self[\time] = time;
			};
			if (count.notNil) {
				self[\count] = count;
			};
			metro[\routine] = fork {
				self[\count].do {
					self[\event].value;
					self[\time].wait;
				}
			}
		};
		metro.stop_ = { |self|
			metro[\routine].stop;
		};
		metro.free_ = { |self|
			metros.remove(self);
		};

		metros = metros.add(metro);

		metro;
	};

	metro.free_all = { |self|
		metros.do { |metro|
			metro.free_();
		};
	};

	metro;
};

var module = IdentityDictionary[
	\init_metro -> init_metro
];

module;
)
