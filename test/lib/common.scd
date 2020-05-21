(
// shared logic for paged user interface

// uses screen, metro, params, mix, poll globals

var include_relative = { |relative_path|
	var path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ relative_path).standardizePath;
	this.executeFile(path);
};

var ui = include_relative.value("ui.scd");

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

/*
var update_ui
var pages

var init_script_polls
var init_params
var init_ui
var load_settings_and_params
var start_script_polls
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
			set_ui_dirty.value;
		};
		script_poll.time_ = 1/fps;
		script_poll
	};
}

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

var module = IdentityDictionary[
	\init -> init,
	\cleanup -> cleanup,
	\redraw -> redraw,
	\enc -> enc,
	\key -> key,
	\get_grid_width -> get_grid_width
];

module
)
