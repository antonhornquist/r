(
// shared logic for paged user interface

// uses screen, metro, params, poll globals

var include_relative = { |relative_path|
	var path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ relative_path).standardizePath;
	if (File.exists(path)) {
		this.executeFile(path);
	} {
		Error("include_relative: file % does not exist".format(path.quote)).throw;
	};
};

var ui = include_relative.value("ui.scd");
var ui_init_arc = ui[\init_arc];
var ui_init_screen = ui[\init_screen];
var ui_init_grid = ui[\init_grid];
var ui_init_midi = ui[\init_midi];
var ui_grid_width = ui[\grid_width];
var ui_refresh = ui[\refresh];
var ui_set_dirty = ui[\set_dirty];
var ui_event_indicator_is_shown = ui[\event_indicator_is_shown];

var bow = include_relative.value("bow.scd");
var spawn_render_ring_function = bow[\spawn_render_ring_function];
var render_ring = spawn_render_ring_function.value();

var hi_level = 15;
var lo_level = 5; // TODO: 4 in lua

var fine = false;
var prev_held = false;
var next_held = false;
var fps;
var current_page = 0;

var script_polls;

var target_page;
var page_trans_div;
var page_trans_frames;

var focus;
var active;

var pages;

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
		var script_poll = ~poll.set_("poll" ++ (i+1)) { |value|
			r_poll[\handler].value(value);
			ui_set_dirty.value();
		};
		script_poll.time_ = 1/fps;
		script_poll
	};
};

var init_params = { |r_params|
	r_params.do { |r_param|
		~params.add_(
			(
				type: r_param[\type],
				id: r_param[\id],
				name: r_param[\name],
				controlspec: r_param[\controlspec],
				action: { |value|
					r_param[\action].value(value);
					ui_set_dirty.value();
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
	var update_ui_metro = ~metro.init_();
	update_ui_metro.event = update_ui;
	update_ui_metro.time = 1/fps;
	update_ui_metro.start_();
};

var get_grid_width = {
	ui_grid_width.value();
};

var update_ui = {
	if (target_page.notNil) {
		update_page_transition.value();
	};
	ui_refresh.value();
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

var mouse_hovers_over_area = { |rect|
	rect.contains(~mouse_over_pos);
};

var get_enc1_value_bounds = {
	var enc1_x = 1; // TODO: DRY
	var enc1_y = 12;
	var the_value = round(~params.get_raw_("output_level")*100).asString;
	var value_x = enc1_x + ~screen.text_extents_("LEVEL") + 3;
	var value_y = enc1_y;
	var value_width = ~screen.text_extents_(the_value);
	Rect(value_x, value_y-12, value_width, 12);
};

var mouse_down_at_enc1_value = {
	var bounds = get_enc1_value_bounds.value();
	bounds.contains(~mouse_down_pos);
};

var mouse_hovers_over_enc1_value = {
	var bounds = get_enc1_value_bounds.value();
	mouse_hovers_over_area.value(bounds);
};

var get_enc2_enc3_value_bounds = { |page, param_index, x, y|
	var ui_param = pages[page][param_index];
	var format_param = { |ui_param|
		var param = ~params.lookup_param_(ui_param.id);
		ui_param[\formatter].value(param);
	};
	var the_value = format_param.value(ui_param).asString;
	var value_x = x;
	var value_y = y + 12;
	var value_width = ~screen.text_extents_(the_value).ceil; // TODO: round in text_extents_ instead?
	Rect(value_x, value_y-12, value_width, 12).debug;
};

var get_enc2_value_bounds = {
	var enc2_x = 10; // TODO: DRY
	var enc2_y = 29;

	var left = floor(current_page);
	// var right = ceil(current_page);
	var offset = current_page - left;
	var pixel_ofs = round(offset*128);

	get_enc2_enc3_value_bounds.value(left, 0, enc2_x-pixel_ofs, enc2_y); // TODO: zero based
};

var mouse_down_at_enc2_value = {
	var bounds = get_enc2_value_bounds.value();
	bounds.contains(~mouse_down_pos);
};

var mouse_hovers_over_enc2_value = {
	var bounds = get_enc2_value_bounds.value();
	mouse_hovers_over_area.value(bounds);
};

var get_enc3_value_bounds = {
	var enc2_x = 10; // TODO: DRY
	var enc2_y = 29;
	var enc3_x = enc2_x + 65;
	var enc3_y = enc2_y;

	var left = floor(current_page);
	//var right = ceil(current_page);
	var offset = current_page - left;
	var pixel_ofs = round(offset*128);

	get_enc2_enc3_value_bounds.value(left, 0, enc3_x-pixel_ofs, enc3_y); // TODO: zero based
};

var mouse_down_at_enc3_value = {
	var bounds = get_enc3_value_bounds.value();
	bounds.contains(~mouse_down_pos);
};

var mouse_hovers_over_enc3_value = {
	var bounds = get_enc3_value_bounds.value();
	mouse_hovers_over_area.value(bounds);
};

var mouse_hovers_over_key2 = {
	var key2_x = 1;
	var key2_y = 63;
	var text_width = ~screen.text_extents_("PREV");
	var bounds = Rect(key2_x, key2_y-12, text_width, 12);
	mouse_hovers_over_area.value(bounds);
};

var mouse_hovers_over_key3 = {
	var key2_x = 1;
	var key2_y = 63;
	var key3_x = key2_x+65;
	var key3_y = key2_y;
	var text_width = ~screen.text_extents_("NEXT");
	var bounds = Rect(key3_x, key3_x-12, text_width, 12);
	mouse_hovers_over_area.value(bounds);
};

var redraw = {
	// TODO
	var enc1_x = 1;
	var enc1_y = 12;

	var enc2_x = 10;
	var enc2_y = 29;

	var enc3_x = enc2_x + 65;
	var enc3_y = enc2_y;

	var page_indicator_y = enc2_y + 16 + 3;

	var key2_x = 1;
	var key2_y = 63;

	var key3_x = key2_x+65;
	var key3_y = key2_y;

	var draw_enc1_widget = {
		var draw_label = {
			~screen.move_(enc1_x, enc1_y);
			~screen.level_(lo_level);
			~screen.text_("LEVEL");
		};
		var draw_current_value = {
			var the_value = round(~params.get_raw_("output_level")*100).asString;
			var value_x = enc1_x + ~screen.text_extents_("LEVEL") + 3;
			var value_y = enc1_y;
			var value_width = ~screen.text_extents_(the_value);
			var value_bounds = Rect(value_x, value_y-12, value_width, 12);
			~screen.move_(value_x, value_y);
			if (focus == 'enc1') {
				~screen.level_((hi_level+lo_level)/2);
			} {
				~screen.level_(hi_level);
			};
			~screen.text_(the_value);
		};
		draw_label.value;
		draw_current_value.value;
	};

	var draw_event_flash_widget = {
		~screen.level_(lo_level);
		~screen.rect_(122, enc1_y-7, 5, 5);
		~screen.fill_();
	};

	var draw_bullet = { |x, y, level|
		~screen.level_(level);
		~screen.rect_(x, y, 2, 2);
		~screen.fill_();
	};

	var translate = { |value, indicator_width|
		round(indicator_width * value);
	};

	var draw_value = { |ind_x, ind_y, ind_x_delta, level|
		var x = ind_x + ind_x_delta;
		draw_bullet.value(x, ind_y, level);
	};

	var strokedraw_value = { |ind_x, ind_y, min_value, max_value, level, width|
		var min_ind_x_delta = translate.value(min_value, width);
		var max_ind_x_delta = translate.value(max_value, width);
		((max_ind_x_delta-min_ind_x_delta) max: 1).do { |idx| // TODO: can be 0 if not max: 1 is here (check lua)
			var ind_x_delta = idx + min_ind_x_delta;
			draw_value.value(ind_x, ind_y, ind_x_delta, level);
		};
	};

	var draw_visual_values = { |ind_x, ind_y, width, visual_values|
		var max_level = 7; // 2; TODO: 2 in lua
		var num_visual_values = visual_values[\content].size;
		if (num_visual_values > 1) {
			var prev_visual_value = visual_values[\content][0]; // TODO: zero based indexing
			(num_visual_values-1).do { |visual_value_idx|
				var idx = visual_value_idx + 1;
				var visual_value = visual_values[\content][idx];

				var min_visual_value = min(prev_visual_value, visual_value);
				var max_visual_value = max(prev_visual_value, visual_value);

				var level = round(max_level/num_visual_values*idx);

				strokedraw_value.value(ind_x, ind_y, min_visual_value, max_visual_value, level, width);

				prev_visual_value = visual_value;
			};
		}
	};

	// TODO: blit this
	var draw_ui_param = { |page, param_index, x, y, focussed|
		var ui_param = pages[page][param_index];
		var draw_label = {
			~screen.move_(x, y);
			~screen.level_(lo_level);
			~screen.text_(ui_param[\label]);
		};
		var draw_current_value = {
			var format_param = { |ui_param|
				var param = ~params.lookup_param_(ui_param.id);
				ui_param[\formatter].value(param);
			};
			var the_value = format_param.value(ui_param).asString;
			var value_x = x;
			var value_y = y + 12;
			var value_width = ~screen.text_extents_(the_value);
			var value_bounds = Rect(value_x, value_y-12, value_width, 12);
			~screen.move_(value_x, value_y);
			if (focussed) {
				~screen.level_((hi_level+lo_level)/2);
			} {
				~screen.level_(hi_level);
			};
			~screen.text_(the_value);

		};
		var draw_widget = {
			var widget_x = x + 1;
			var widget_y = y + 14;
			var visual_values = ui_param[\visual_values];
			var raw_value = ~params.get_raw_(ui_param[\id]);

			if (visual_values.notNil) {
				draw_visual_values.value(widget_x, widget_y, ui_param[\label_width], visual_values);
			};

			draw_value.value(widget_x, widget_y, translate.value(raw_value, ui_param[\label_width]), hi_level);
		};

		draw_label.value;
		draw_current_value.value;
		draw_widget.value;
	};

	var draw_enc2_widget = {
		var left = floor(current_page);
		var right = ceil(current_page);
		var offset = current_page - left;
		var pixel_ofs = round(offset*128);

		draw_ui_param.value(
			left,
			0,
			enc2_x-pixel_ofs,
			enc2_y,
			focus == 'enc2' // TODO: on transition consider this unfocussed?
		); // TODO: zero based


		if (left != right) {
			draw_ui_param.value(
				right,
				0,
				enc2_x+128-pixel_ofs,
				enc2_y,
				false // TODO: on transition consider this unfocussed?
			); // TODO: zero based
		};
	};

	var draw_enc3_widget = {
		var left = floor(current_page);
		var right = ceil(current_page);
		var offset = current_page - left;
		var pixel_ofs = round(offset*128);

		draw_ui_param.value(
			left,
			1,
			enc3_x-pixel_ofs,
			enc3_y,
			focus == 'enc3' // TODO: on transition consider this unfocussed?
		); // TODO: zero based

		if (left != right) {
			draw_ui_param.value(
				right,
				1,
				enc3_x+128-pixel_ofs,
				enc3_y,
				false // TODO: on transition consider this unfocussed?
			); // TODO: zero based
		};
	};
    
	var draw_page_indicator = {
		var div = 128/pages.size;

		var x = round(current_page*div); // TODO: zero based indexing
		var y = page_indicator_y;
		var width = round(div);
		var height = 2;

		~screen.level_(lo_level);
		~screen.rect_(x, y, width, height);
		~screen.fill_();
	};

	var draw_key2key3_widget = {
		~screen.move_(key2_x+42, key2_y);
		~screen.level_(hi_level);
		~screen.text_("FN");
	};

	var draw_key_widget = { |widget_x, widget_y, text, key_held, focussed|
		~screen.move_(widget_x, widget_y);
		if (key_held and: fine.not) {
			~screen.level_(hi_level);
		} {
			if (focussed) {
				~screen.level_((hi_level+lo_level)/2);
			} {
				~screen.level_(lo_level);
			};
		};
		~screen.text_(text);
	};

	var draw_key2_widget = {
		draw_key_widget.value(key2_x, key2_y, "PREV", prev_held, focus == 'key2');
	};

	var draw_key3_widget = {
		draw_key_widget.value(key3_x, key3_y, "NEXT", next_held, focus == 'key3');
	};

	~screen.font_size(16);
	~screen.clear_(); // TODO: do this in redraw() ?

	draw_enc1_widget.value();

	if (ui_event_indicator_is_shown.value()) {
		draw_event_flash_widget.value();
	};

	draw_enc2_widget.value();
	draw_enc3_widget.value();

	draw_page_indicator.value();

	if (fine) {
		draw_key2key3_widget.value();
	};

	draw_key2_widget.value();
	draw_key3_widget.value();

	~screen.update_();
};

var enc = { |n, delta|
	var d;
	if (fine) {
		d = delta/5
	} {
		d = delta
	};
	if (n == 1) {
		~params.delta_("output_level", d);
		ui_set_dirty.value();
	} {
		~params.delta_(get_param_id_for_current_page.value(n-2), d); // TODO: zero based
	};
};

var key = { |n, z|
	var page;

	if (target_page.notNil) {
		page = target_page;
	} {
		page = get_active_page.value();
	};

	case
	{n == 2} {
		if (z == 1) {
			page = page - 1;
			if (page < 0) { // TODO: zero based indexing
				page = pages.size-1; // TODO: zero based indexing
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
			if (page > (pages.size-1)) { // TODO: zero based indexing
				page = 0; // TODO: zero based indexing
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

var default_arc_delta_handler = { |n, delta|
	var d;
	var id;
	var val;
	if (fine) {
		d = delta/5;
	} {
		d = delta;
	};
	id = get_param_id_for_current_page.value(n);
	val = ~params.get_raw_(id);
	~params.set_raw_(id, val+d/500);
};

var draw_arc = { |my_arc, value1, visual_values1, value2, visual_values2|
	var draw_ring = { |ring, value, visual_values|
		var led_levels = render_ring.value(value, visual_values);
		led_levels.do { |led_level, i|
			my_arc.led_(ring, i, led_level);
		};
	};
	my_arc.all_(0);
	draw_ring.value(1, value1, visual_values1);
	draw_ring.value(2, value2, visual_values2);
};

var set_page = { |page|
	current_page = page;
};

var get_active_page = {
	round(current_page);
};

var get_param_id_for_current_page = { |n|
	var page = get_active_page.value();
	pages[page][n].id;
};

var transition_to_page = { |page|
	target_page = page;
	page_trans_frames = fps/5;
	page_trans_div = (target_page - current_page) / page_trans_frames;
};

var load_settings = {
	// TODO
	\load_settings.debug;
};

var save_settings = {
	// TODO
	\save_settings.debug;
};

var default_arc_refresh_handler = { |my_arc|
	render_active_page_on_arc.value(my_arc);
};

var render_active_page_on_arc = { |my_arc|
	var page = pages[get_active_page.value()];

	var visual_values1, visual_values2;

	// TODO: zero-based indexing
	if (page[0][\visual_values].notNil) { // TODO: refactor to first_page
		visual_values1 = page[0][\visual_values][\content]
	};

	// TODO: zero-based indexing
	if (page[1][\visual_values].notNil) { // TODO: refactor to second_page
		visual_values2 = page[1][\visual_values][\content]
	};

	draw_arc.value(
		my_arc,
		~params.get_raw_(get_param_id_for_current_page.value(0)), // TODO: zero-based indexing
		visual_values1,
		~params.get_raw_(get_param_id_for_current_page.value(1)), // TODO: zero-based indexing
		visual_values2
	);
};

var cleanup = { |settings_file|
	save_settings.value(settings_file);
	// ~params.write_();
};

var load_settings_and_params = { |settings_file|
	load_settings.value(settings_file);
	// ~params.read_(); // TODO
	~params.bang_();
};

var start_script_polls = {
	if (script_polls.notNil) {
		script_polls.do { |script_poll|
			script_poll.start_();
		};
	};
};

var set_ui_dirty = {
	ui_set_dirty.value();
};

var mouse = { |what ... args|
	[what, args].debug;
	case
	{ what == "leave" } {
		~mouse_over_pos = nil;
	}
	{ what == "over" } {
		var x = args[0], y = args[1];
		var prev_focus = focus;

		~mouse_over_pos = x@y;

		case
		{ mouse_hovers_over_enc1_value.value } {
			focus = 'enc1';
		}
		{ mouse_hovers_over_enc2_value.value } {
			focus = 'enc2';
		}
		{ mouse_hovers_over_enc3_value.value } {
			focus = 'enc3';
		}
		{ mouse_hovers_over_key2.value } {
			focus = 'key2';
		}
		{ mouse_hovers_over_key3.value } {
			focus = 'key3';
		}
		{ true } {
			focus = nil;
		};
		if (prev_focus != focus) {
			ui_set_dirty.value();
		};
	}
	{ what == "down" } {
		var x = args[0], y = args[1];
		var prev_active = active;
		~mouse_down_pos = x@y;

		case
		{ focus == 'key2' } {
			key.value(2, 1);
		}
		{ focus == 'key3' } {
			key.value(3, 1);
		};

		active = focus;

		if (prev_active != active) {
			ui_set_dirty.value();
		};
	}
	{ what == "move" } {
		var x = args[0], y = args[1];
		~prev_mouse_move_pos = ~mouse_move_pos;
		~mouse_move_pos = x@y;
		~mouse_move_delta = (~prev_mouse_move_pos ? ~mouse_down_pos) - (x@y);
		if (~mouse_move_delta.y != 0) {
			case
			{active == 'enc1'} {
				enc.value(1, ~mouse_move_delta.y);
			}
			{active == 'enc2'} {
				enc.value(2, ~mouse_move_delta.y);
			}
			{active == 'enc3'} {
				enc.value(3, ~mouse_move_delta.y);
			};
		};
	}
	{ what == "up" } {
		var x = args[0], y = args[1];
		var prev_active = active;

		~mouse_move_pos = nil;

		case
		{ active == 'key2' } {
			key.value(2, 0);
		}
		{ active == 'key3' } {
			key.value(3, 0);
		};

		active = nil;

		if (prev_active != active) {
			ui_set_dirty.value();
		};
	}
	{ what == "wheel" } {
		var x_delta = args[0], y_delta = args[1];

		if (y_delta != 0) {
			case
			{focus == 'enc1'} {
				enc.value(1, y_delta*(-1));
			}
			{focus == 'enc2'} {
				enc.value(2, y_delta*(-1));
			}
			{focus == 'enc3'} {
				enc.value(3, y_delta*(-1));
			};
		};
	}
};

var module = IdentityDictionary[
	\init -> init,
	\redraw -> redraw,
	\enc -> enc,
	\key -> key,
	\cleanup -> cleanup,
	\get_grid_width -> get_grid_width,
	\get_active_page -> get_active_page,
	\set_ui_dirty -> set_ui_dirty,
	\mouse -> mouse,
];

module
)
