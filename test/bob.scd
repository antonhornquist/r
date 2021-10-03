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
	// scriptname: bob
	// v1.3.0 @jah
	var bob_spec = include_relative.value('lib/bob_spec.scd');
	var bob_spec_init = bob_spec[\init];

	var common = include_relative.value("lib/common.scd");
	var common_init = common[\init];
	var common_redraw = common[\redraw];
	var common_key = common[\key];
	var common_mouse = common[\mouse];
	var common_add_params = common[\add_params];
	var common_render_arc = common[\render_arc];
	var common_get_param_id_for_current_page = common[\get_param_id_for_current_page];
	var common_load_settings_and_params = common[\load_settings_and_params];

	var ui_dirty = false;

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
	var update_page_transition = { |script_context|
		var state = script_context[\state];
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
		var state = script_context[\state];
		var target_page = state[\target_page];
		if (target_page.notNil) {
			update_page_transition.value(script_context);
		};

		update_event_indicator.value();

		// TODO update_grid_width.value();

		if (ui_dirty) {

/*
	TODO
			refresh_grid.value(); // TODO: naming
			grid_device.refresh_();
*/

			common_render_arc.value(script_context, arc_device);
			arc_device.refresh_();

			~redraw.value();

			ui_dirty = false;
		};
	};

	var settings_file = "bob.data";
	var ui_refresh_rate = 35;

	var script_context;

	var create_polls = { |script_context, poll_specs, refresh_rate|
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

	var create_and_start_polls = { |script_context, poll_specs, refresh_rate|
		var polls = create_polls.value(script_context, poll_specs, refresh_rate);
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

			var state = script_context[\state];

			flash_event.value();

			if (state[\fine]) {
				d = delta/5;
			} {
				d = delta;
			};
			id = common_get_param_id_for_current_page.value(script_context, n-1); // TODO: zero-based
			val = ~params.get_raw_(id);
			~params.set_raw_(id, val+(d/500));
		};

		init_ui_refresh_metro.value();
	};

	~engine.name = 'R';

	~init = {
		var bob_spec_instance = bob_spec_init.value(
			(
				engine_global: ~engine,
				visual_buf_size: round(ui_refresh_rate/20)
			)
		);

		var ui_spec = (
			// TODO arc_device: ~arc.connect_(),
			pages: [
				[ (id: 'cutoff'), (id: 'resonance') ],
				[ (id: 'lfo_rate'), (id: 'lfo_to_cutoff') ],
				[ (id: 'envf_attack'), (id: 'envf_decay') ],
				[ (id: 'envf_sensitivity'), (id: 'env_to_cutoff') ],
			],
			refresh_rate: ui_refresh_rate
		);

		common_add_params.value(bob_spec_instance[\param_specs], ~params);

		script_context = common_init.value(
			(
				globals: (
					screen: ~screen,
					params: ~params
				),
				visual_values: bob_spec_instance[\visual_values],
				ui_spec: ui_spec,
			)
		);

		common_load_settings_and_params.value(settings_file, ~params);
		create_and_start_polls.value(script_context,  bob_spec_instance[\poll_specs], ui_refresh_rate);

		init_ui.value();
	};

/*
	TODO
	~cleanup = {
		common_cleanup.value(settings_file);
	};
*/

	~redraw = {
		var ui_spec = script_context[\ui_spec];
		var pages = ui_spec[\pages];

		var state = script_context[\state];
		common_redraw.value(~params, ~screen, pages, state, show_event_indicator);
	};

/*
	TODO
	~enc = { |n, delta|
		common_enc.value(n, delta);
	};
*/

	~key = { |n, z|
		ui_dirty = common_key.value(script_context, n, z);
	};

	~mouse = { |... args| // TODO: get away from using varargs for ~mouse
		common_mouse.value(*([script_context]++args)); // TODO: get away from using varargs for ~mouse
		ui_dirty = true;
	};
};
)
