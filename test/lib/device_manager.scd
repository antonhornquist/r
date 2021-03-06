(
// utility library for single-grid, single-arc, single-midi device script UIs
// written to track when UI is invalidated and needs to be refreshed
//
// main entry points:
// UI.init_arc - invoked if an arc is to be used. has to be passed a device (ie. return value from arc.connect()), and optionally sets up callbacks for receiving enc delta messages (on_delta) and refreshing arc leds (on_refresh) when arc UI is invalidated
// UI.init_grid - invoked if a grid is to be used. has to be passed a device (ie. return value from grid.connect()), and optionally sets up callbacks for receiving grid key messages (on_key) and refreshing grid leds (on_refresh) when grid UI is invalidated
// UI.init_midi - invoked if a midi device is to be used. has to be passed a device (ie. return value from midi.connect()), and optionally a callback for receiving incoming midi messages (on_event)
// UI.init_screen - invoked if norns screen is to be used. has to be passed a callback for refreshing screen (on_refresh) when screen UI is invalidated.
// UI.refresh - to be triggered from script recurringly, will check and refresh invalidated UIs and refresh tracked device properties (whether device is connected, device bounds). additionally a flag for whether an incoming event was recently handled (UI.show_event_indicator) is continuously updated.

var init = { |config|
	var instance = (
		// event indicator flag
		show_event_indicator: false,
		event_flash_frames: 5, // TODO: this ought to be initialized since it's refresh FPS rate affects time
		event_flash_frame_counter: nil,

		// arc handling
		arc_is_inited: false,
		arc_connected: false,
		arc_dirty: false,
		// grid handling
		grid_is_inited: false,
		grid_connected: false,
		grid_dirty: false,
		grid_width: nil,
		// midi handling
		midi_is_inited: false,
		midi_device_connected: false,
		// screen handling
		screen_dirty: false,

		// state
		arc_device: nil,
		arc_delta_callback: nil,
		arc_refresh_callback: nil,

		grid_device: nil,
		grid_key_callback: nil,
		grid_refresh_callback: nil,

		midi_device: nil,
		midi_event_callback: nil,

		screen_refresh_callback: nil,
		screen_global: nil
	);

	if (config.arc.notNil) {
		init_arc.value(instance, config.arc);
	};

	if (config.grid.notNil) {
		init_grid.value(instance, config.grid);
	};

	if (config.midi.notNil) {
		init_midi.value(instance, config.midi);
	};

	if (config.screen.notNil) {
		init_screen.value(instance, config.screen);
	};

	instance;
};

var init_arc = { |instance, config|
	var arc_device;
	var arc_delta_callback;

	if (config.device == nil) {
		Error("init_arc: device is mandatory").throw;
	};

	arc_device = config.device;

	instance[\arc_device] = arc_device;
	arc_delta_callback = config[\on_delta];
	arc_device[\delta] = { |n, delta| // not .delta notation to suppress self argument?
		flash_event.value();
		arc_delta_callback.value(n, delta);
	};
	instance[\arc_refresh_callback] = config[\on_refresh];
	instance[\arc_is_inited] = true;
};

var init_grid = { |instance, config|
	var grid_device;
	var grid_key_callback;

	if (config.device == nil) {
		Error("init_grid: device is mandatory").throw;
	};

	grid_device = config.device;

	instance[\grid_device] = grid_device;
	grid_key_callback = config[\on_key];
	grid_device[\key] = { |x, y, s| // not .key notation to suppress self argument?
		flash_event.value();
		grid_key_callback.value(x, y, s);
	};
	instance[\grid_refresh_callback] = config[\on_refresh];
	instance[\grid_is_inited] = true;
};

var init_midi = { |instance, config|
	var midi_device;
	var midi_event_callback;

	if (config.device == nil) {
		Error("init_midi: device is mandatory").throw;
	};

	midi_device = config.device;

	instance[\midi_device] = midi_device;
	midi_event_callback = config[\on_event];
	midi_device[\event] = { |data| // not .event notation to suppress self argument?
		flash_event.value();
		midi_event_callback.value(data);
	};
	instance[\midi_is_inited] = true;
};

var init_screen = { |instance, config|
	instance[\screen_global] = config[\screen_global] ?? { Error("screen global is required").throw };
	instance[\screen_refresh_callback] = config[\on_refresh];
};

// refresh logic

var refresh = { |instance|
	update_event_indicator.value(instance);

	if (instance[\arc_is_inited]) {
		check_arc_connected.value(instance);

		if (instance[\arc_dirty]) {
			var arc_device = instance[\arc_device];
			if (instance[\arc_refresh_callback].notNil) {
				instance[\arc_refresh_callback].value(arc_device);
			};
			arc_device.refresh_();
			instance[\arc_dirty] = false;
		};
	};

	if (instance[\grid_is_inited]) {
		check_grid_connected.value(instance);
		update_grid_width.value(instance);

		if (instance[\grid_dirty]) {
			var grid_device = instance[\grid_device];
			if (instance[\grid_refresh_callback].notNil) {
				instance[\grid_refresh_callback].value(grid_device);
			};
			grid_device.refresh_();
			instance[\grid_dirty] = false;
		};
	};

	if (instance[\midi_is_inited]) {
		check_midi_connected.value(instance);
	};

	if (instance[\screen_dirty]) {
		if (instance[\screen_refresh_callback].notNil) {
			instance[\screen_refresh_callback].value();
		};
		instance[\screen_global].update_(); // norns global
		instance[\screen_dirty] = false;
	};
};

var set_dirty = { |instance|
	instance[\arc_dirty] = true;
	instance[\grid_dirty] = true;
	instance[\screen_dirty] = true;
};

// event flash

var flash_event = { |instance|
	instance[\event_flash_frame_counter] = instance[\event_flash_frames];
};
  
var update_event_indicator = { |instance|
	if (instance[\event_flash_frame_counter].notNil) {
		instance[\event_flash_frame_counter] = instance[\event_flash_frame_counter] - 1;
		case
		{ instance[\event_flash_frame_counter] == 0 } {
			instance[\event_flash_frame_counter] = nil;
			instance[\show_event_indicator] = false;
			set_dirty.value();
		}
		{ instance[\show_event_indicator].not } {
			instance[\show_event_indicator] = true;
			set_dirty.value();
		};
	};
};

var event_indicator_is_shown = { |instance|
	instance[\show_event_indicator] 
};

// arc

var check_arc_connected = { |instance|
	var arc_device = instance[\arc_device];
	var arc_check = arc_device.device_ != nil;
	if (instance[\arc_connected] != arc_check) {
		instance[\arc_connected] = arc_check;
		instance[\arc_dirty] = true;
	};
};
  
// grid

var update_grid_width = { |instance|
	var grid_device = instance[\grid_device];
	if (grid_device.device_.notNil) {
		if (instance[\grid_width] != grid_device.cols_) {
			instance[\grid_width] = grid_device.cols_;
			instance[\grid_dirty] = true;
		};
	};
};

var grid_width = { |instance|
	instance[\grid_width]
};

var check_grid_connected = { |instance|
	var grid_device = instance[\grid_device];
	var grid_check = (grid_device.device != nil);
	if (instance[\grid_connected] != grid_check) {
		instance[\grid_connected] = grid_check;
		instance[\grid_dirty] = true;
	};
};

// midi

// TODO
var check_midi_connected = { |instance|
	var midi_device = instance[\midi_device];
	var midi_device_check = midi_device.device_ != nil;
	if (instance[\midi_device_connected] != midi_device_check) {
		instance[\midi_device_connected] = midi_device_check;
	};
};

var module = IdentityDictionary[
	\init -> init,
	\grid_width -> grid_width,
	\refresh -> refresh,
	\set_dirty -> set_dirty,
	\event_indicator_is_shown -> event_indicator_is_shown
];

module
)
