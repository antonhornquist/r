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
	// scriptname: rymd
	// v1.3.0 @jah
	var rymd_spec = include_relative.value('lib/rymd_spec.scd');
	var rymd_spec_init = rymd_spec[\init];

	var common = include_relative.value("lib/common.scd");
	var common_init_script_state = common[\init_script_state];
	var common_redraw = common[\redraw];
	var common_enc = common[\enc];
	var common_key = common[\key];
	var common_mouse = common[\mouse];
	var common_add_params = common[\add_params];
	var common_render_arc = common[\render_arc];
	var common_get_param_id_for_current_page = common[\get_param_id_for_current_page];
	var common_load_settings_and_params = common[\load_settings_and_params];
	var common_calculate_ui_page_label_widths = common[\calculate_ui_page_label_widths];

	var ui_dirty = false;

	var pages = [
		[ (id: 'direct'), (id: 'delay_send') ],
		[ (id: 'delay_time_left'), ( id: 'delay_time_right') ],
		[ (id: 'damping'), (id: 'feedback') ],
		[ (id: 'mod_rate'), (id: 'delay_time_mod_depth') ]
	];

	// arc

	var arc_device;

/*
	TODO
	// grid

	var grid_device;
	var grid_width = Ref.new; // TODO: do not wrap as Ref

	var update_grid_width = {
		if (grid_device.device_.notNil) {
			if (grid_width.dereference != grid_device.cols_) {
				grid_width.set(grid_device.cols_);
			};
		};
	};
*/

	// event flash

	var show_event_indicator = false;

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
				ui_dirty = true;
			}
			{ show_event_indicator.not } {
				show_event_indicator = true;
				ui_dirty = true;
			};
		};
	};

	// ui refresh logic
	var update_page_transition = { |state| // TODO: state -> script_state ??
		var current_page = state[\current_page];
		var target_page = state[\target_page];
		var page_trans_div = state[\page_trans_div];
		var new_current_page;
		new_current_page = current_page + page_trans_div;
		state[\page_trans_frames] = state[\page_trans_frames] - 1;
		if (state[\page_trans_frames] == 0) {
			new_current_page = target_page;
			state[\target_page] = nil;
		};
		state[\current_page] = new_current_page;
		ui_dirty = true;
	};

	var refresh_ui = {
		var target_page = script_state[\target_page];
		if (target_page.notNil) {
			update_page_transition.value(script_state);
		};

		update_event_indicator.value();

		// TODO update_grid_width.value();

		if (ui_dirty) {

/*
	TODO
			refresh_grid.value(); // TODO: naming
			grid_device.refresh_();
*/

			common_render_arc.value(~params, script_state, pages, arc_device);
			arc_device.refresh_();

			~redraw.value();

			ui_dirty = false;
		};
	};

	var settings_file = "rymd.data";
	var ui_refresh_rate = 35;

	var script_state;

	var create_polls = { |poll_specs, refresh_rate|
		poll_specs.collect { |poll_spec, i|
			var script_poll = ~poll.set__("poll" ++ (i+1)) { |value|
				poll_spec[\handler].value(value);
				ui_dirty = true;
			};
			script_poll.time_ = 1/refresh_rate;
			script_poll
		};
	};

	var start_polls = { |polls|
		if (polls.notNil) {
			polls.do { |script_poll|
				script_poll.start_();
			};
		};
	};

	var create_and_start_polls = { |poll_specs, refresh_rate|
		var polls = create_polls.value(poll_specs, refresh_rate);
		start_polls.value(polls);
	};

	var init_ui_refresh_metro = {
		var ui_refresh_metro = ~metro.init_();
		ui_refresh_metro.event = refresh_ui;
		ui_refresh_metro.time = 1/ui_refresh_rate;
		ui_refresh_metro.start_();
	};

	var init_ui = {
		arc_device = ~arc.connect_();

		arc_device[\delta] = { |n, delta| // not .delta notation to suppress self argument?
			var d;
			var id;
			var val;

			flash_event.value();

			if (script_state[\fine]) {
				d = delta/5;
			} {
				d = delta;
			};
			id = common_get_param_id_for_current_page.value(pages, script_state, n-1); // TODO: zero-based
			val = ~params.get_raw_(id);
			~params.set_raw_(id, val+(d/500));
			ui_dirty = true;
		};

		init_ui_refresh_metro.value();
	};

	~engine.name = 'R';

	~init = {
		var spec_instance = rymd_spec_init.value(
			(
				engine_global: ~engine,
				visual_buf_size: round(ui_refresh_rate/20)
			)
		);

		common_add_params.value(spec_instance[\param_specs], ~params);

		script_state = common_init_script_state.value(spec_instance[\visual_values]);

		common_calculate_ui_page_label_widths.value(~params, ~screen, pages);

		common_load_settings_and_params.value(settings_file, ~params);
		create_and_start_polls.value(spec_instance[\poll_specs], ui_refresh_rate);

		init_ui.value();
	};

/*
	TODO
	~cleanup = {
		common_cleanup.value(settings_file);
	};
*/

	~redraw = {
		common_redraw.value(~params, ~screen, pages, script_state, show_event_indicator);
	};

	~enc = { |n, delta|
		common_enc.value(~params, pages, script_state, n, delta);
		ui_dirty = true;
	};

	~key = { |n, z|
		common_key.value(pages, ui_refresh_rate, script_state, n, z);
		ui_dirty = true;
	};

	~mouse = { |... args| // TODO: get away from using varargs for ~mouse
		common_mouse.value(*([~params, ~screen, pages, ui_refresh_rate, script_state]++args)); // TODO: get away from using varargs for ~mouse
		ui_dirty = true;
	};
};
)
