(
// utility library for single-grid, single-arc, single-midi device script UIs
// written to track when UI is invalidated and needs to be refreshed
// uses screen global
//
// main entry points:
// UI.init_arc - invoked if an arc is to be used. has to be passed a device (ie. return value from arc.connect()), and optionally sets up callbacks for receiving enc delta messages (on_delta) and refreshing arc leds (on_refresh) when arc UI is invalidated
// UI.init_grid - invoked if a grid is to be used. has to be passed a device (ie. return value from grid.connect()), and optionally sets up callbacks for receiving grid key messages (on_key) and refreshing grid leds (on_refresh) when grid UI is invalidated
// UI.init_midi - invoked if a midi device is to be used. has to be passed a device (ie. return value from midi.connect()), and optionally a callback for receiving incoming midi messages (on_event)
// UI.init_screen - invoked if norns screen is to be used. has to be passed a callback for refreshing screen (on_refresh) when screen UI is invalidated.
// UI.refresh - to be triggered from script recurringly, will check and refresh invalidated UIs and refresh tracked device properties (whether device is connected, device bounds). additionally a flag for whether an incoming event was recently handled (UI.show_event_indicator) is continuously updated.

// event indicator flag
var show_event_indicator = false;
// arc handling
var arc_connected = false;
var arc_dirty = false;
// grid handling
var grid_connected = false;
var grid_dirty = false;
var grid_width = nil;
// midi handling
var midi_device_connected = false;
// screen handling
var screen_dirty = false;

// state
var arc_device;
var arc_delta_callback;
var arc_refresh_callback;
var arc_is_inited = false;

var grid_device;
var grid_key_callback;
var grid_refresh_callback;
var grid_is_inited = false;

var midi_device;
var midi_event_callback;
var midi_is_inited = false;

var screen_refresh_callback;
var screen_global;

// refresh logic

var refresh = {
	update_event_indicator.value();

	if (arc_is_inited) {
		check_arc_connected.value();

		if (arc_dirty) {
			if (arc_refresh_callback.notNil) {
				arc_refresh_callback.value(arc_device);
			};
			arc_device.refresh_();
			arc_dirty = false;
		};
	};

	if (grid_is_inited) {
		check_grid_connected.value();
		update_grid_width.value();

		if (grid_dirty) {
			if (grid_refresh_callback.notNil) {
				grid_refresh_callback.value(grid_device);
			};
			grid_device.refresh_();
			grid_dirty = false;
		};
	};

	if (midi_is_inited) {
		check_midi_connected.value();
	};

	if (screen_dirty) {
		if (screen_refresh_callback.notNil) {
			screen_refresh_callback.value();
		};
		screen_global.update_(); // norns global
		screen_dirty = false;
	};
};

var set_dirty = {
	// \set_dirty.debug;
	arc_dirty = true;
	grid_dirty = true;
	screen_dirty = true;
};

// event flash

var event_flash_frames = 5; // TODO: this ought to be initialized since it's refresh FPS rate affects time
var event_flash_frame_counter = nil;

var flash_event = {
	event_flash_frame_counter = event_flash_frames;
};
  
var update_event_indicator = {
	if (event_flash_frame_counter.notNil) {
		event_flash_frame_counter = event_flash_frame_counter - 1;
		case
		{ event_flash_frame_counter == 0 } {
			event_flash_frame_counter = nil;
			show_event_indicator = false;
			set_dirty.value();
		}
		{ show_event_indicator.not } {
			show_event_indicator = true;
			set_dirty.value();
		};
	};
};

var event_indicator_is_shown = {
	show_event_indicator 
};

// arc

var init_arc = { |config|
	if (config.device == nil) {
		Error("init_arc: device is mandatory").throw;
	};

	arc_device = config.device;

	arc_delta_callback = config[\on_delta];
	arc_device[\delta] = { |n, delta| // not .delta notation to suppress self argument?
		flash_event.value();
		arc_delta_callback.value(n, delta);
	};
	arc_refresh_callback = config[\on_refresh];
	arc_is_inited = true;
};

var check_arc_connected = {
	var arc_check = arc_device.device_ != nil;
	if (arc_connected != arc_check) {
		arc_connected = arc_check;
		arc_dirty = true;
	};
};
  
// grid

var init_grid = { |config|
	if (config.device == nil) {
		Error("init_grid: device is mandatory").throw;
	};

	grid_device = config.device;

	grid_key_callback = config[\on_key];
	grid_device[\key] = { |x, y, s| // not .key notation to suppress self argument?
		flash_event.value();
		grid_key_callback.value(x, y, s);
	};
	grid_refresh_callback = config[\on_refresh];
	grid_is_inited = true;
};

var update_grid_width = {
	if (grid_device.device_.notNil) {
		if (grid_width != grid_device.cols_) {
			grid_width = grid_device.cols_;
		};
	};
};

var check_grid_connected = {
	var grid_check = (grid_device.device != nil);
	if (grid_connected != grid_check) {
		grid_connected = grid_check;
		grid_dirty = true;
	};
};

// midi

var init_midi = { |config|
	if (config.device == nil) {
		Error("init_midi: device is mandatory").throw;
	};

	midi_device = config.device;

	midi_event_callback = config[\on_event];
	midi_device[\event] = { |data| // not .event notation to suppress self argument?
		flash_event.value();
		midi_event_callback.value(data);
	};
	midi_is_inited = true;
};

// TODO
var check_midi_connected = {
	var midi_device_check = midi_device.device_ != nil;
	if (midi_device_connected != midi_device_check) {
		midi_device_connected = midi_device_check;
	};
};

// screen

var init_screen = { |config|
	screen_global = config[\screen_global] ?? { Error("screen global is required").throw };
	screen_refresh_callback = config[\on_refresh];
};

var module = IdentityDictionary[
	\init_arc -> init_arc,
	\init_screen -> init_screen,
	\init_grid -> init_grid,
	\init_midi -> init_midi,
	\grid_width -> grid_width,
	\refresh -> refresh,
	\set_dirty -> set_dirty,
	\event_indicator_is_shown -> event_indicator_is_shown
];

module
)
