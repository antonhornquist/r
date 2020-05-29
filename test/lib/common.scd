(
// shared logic for paged user interface

// uses screen, metro, params, mix, poll globals

var include_relative = { |relative_path|
	var path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ relative_path).standardizePath;
	this.executeFile(path);
};

var ui = include_relative.value("ui.scd");
var ui_init_arc = ui[\init_arc];
var ui_init_screen = ui[\init_screen];
var ui_init_grid = ui[\init_grid];
var ui_init_midi = ui[\init_midi];
var ui_grid_width = ui[\grid_width];
var ui_refresh = ui[\refresh];
var ui_set_dirty = ui[\set_dirty];

var bow = include_relative.value("bow.scd");
var spawn_render_ring_function = bow[\spawn_render_ring_function];
var render_ring = spawn_render_ring_function.value();

var hi_level = 15;
var lo_level = 4;

var fine = false;
var prev_held = false;
var next_held = false;
var fps;
var current_page;

var script_polls;

var pages;

/*
var update_ui

var start_ui
*/

var init = { |r_polls, r_params, ui, settings_file, arg_fps|
	fps = arg_fps;

	init_script_polls.value(r_polls);
	init_params.value(r_params);
	init_ui.value(ui);
	load_settings_and_params.value(settings_file);
	start_script_polls.value();
	start_ui.value();
};

var init_script_polls = { |r_polls|
	script_polls = r_polls.collect { |r_poll, i|
		var script_poll = ~poll.set_("poll" ++ (i+1)) {
			r_poll.handler_(value);
			set_ui_dirty.value();
		};
		script_poll.time_ = 1/fps;
		script_poll
	};
};

var init_params = { |r_params|
	r_params.do { |r_param|
		~params.add_(
			(
				type: r_param.type_,
				id: r_param.id_,
				name: r_param.name_,
				controlspec: r_param.controlspec_,
				action: { |value|
					r_param.action_(value);
					set_ui_dirty.value();
				}
			)
		);
	};
};

var init_ui = { |conf|
	var screen_conf;

	if (conf.arc.notNil) {
		var arc_conf = conf.arc;

		if (arc_conf.on_delta.isNil) {
			arc_conf.on_delta = default_arc_delta_handler;
		};

		if (arc_conf.on_refresh.isNil) {
			arc_conf.on_refresh = default_arc_refresh_handler;
		};

		ui_init_arc.value(arc_conf);
	};

	if (conf.screen.notNil) {
		screen_conf = conf.screen;
	} {
		screen_conf = (
			on_refresh: default_screen_refresh_handler
		);
	};
	ui_init_screen.value(screen_conf);

	if (conf.grid.notNil) {
		ui_init_grid.value(conf.grid);
	};

	if (conf.midi.notNil) {
		ui_init_midi.value(conf.midi);
	};

	pages = conf.pages ? [];
	calculate_ui_label_widths.value(pages);
};

var calculate_ui_label_widths = { |pages|
	~screen.font_size_(16);
	pages.do { |page, index|
		pages[index][0].label_width = ~screen.text_extents_(page[0].label) - 2;
		pages[index][1].label_width = ~screen.text_extents_(page[1].label) - 2;
	};
};

var start_ui = {
	var update_ui_metro = metro.init_();
	update_ui_metro.event = update_ui;
	update_ui_metro.time = 1/fps;
	update_ui_metro.start_();
};

var get_grid_width = {
	ui_grid_width.value();
};

var update_page_transition = {
	current_page = current_page + page_trans_div;
	page_trans_frames = page_trans_frames - 1;
	if (page_trans_frames == 0) {
		current_page = target_page;
		target_page = nil;
	};
	ui_set_dirty.value();
};

var default_screen_refresh_handler = {
	~redraw.value();
};

var redraw = {
};

var enc = { |n, delta|
	var d;
	if (fine) {
		d = delta/5
	} {
		d = delta
	};
	if (n == 1) {
		~mix.delta_("output", d);
		UI.screen_dirty = true;
	} {
		~params.delta_(get_param_id_for_current_page(n-1), d);
	};
};

var key = { |n, z|
	var page;

	if (target_page) {
		page = target_page;
	} {
		page = get_active_page.value();
	};

	case
	{n == 2} {
		if (z == 1) {
			page = page - 1;
			if (page < 1) {
				page = pages.size;
			};

			transition_to_page.value(page);

			prev_held = true;
		} {
			prev_held = false;
		};
		ui_set_dirty.value();
	}
	{n == 3} {
		if (z == 1) {
			page = page + 1;
			if (page > pages.size) {
				page = 1;
			};

			transition_to_page.value(page);

			next_held = true;
		} {
			next_held = false
		};
		ui_set_dirty.value();
	};

	fine = (prev_held and: next_held);
};

var update_ui = {
	if (target_page.notNil) {
		update_page_transition.value();
	};
	ui_refresh.value();
};

var load_settings_and_params = { |settings_file|
	load_settings.value(settings_file);
	~params.read_(); // TODO
	~params.bang_();
};

var start_script_polls = {
	if (script_polls.notNil) {
		script_polls.do { |script_poll|
			script_poll.start_();
		};
	};
};

var module = IdentityDictionary[
	\init -> init,
	\redraw -> redraw,
	\enc -> enc,
	\key -> key,
	\cleanup -> cleanup,
	\get_grid_width -> get_grid_width,
	\get_active_page -> get_active_page
];

module
)
