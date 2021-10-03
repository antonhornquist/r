(
// shared logic for paged user interface

var include_relative = { |relative_path|
	var path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ relative_path).standardizePath;
	if (File.exists(path)) {
		var result = this.executeFile(path);
		if (result.isNil) { Error("error importing %".format(path)).throw; } { result }; // TODO: adopt in other places too
	} {
		Error("include_relative: file % does not exist".format(path.quote)).throw;
	};
};

// TODO arc_common - start
var bow = include_relative.value("bow.scd");
var bob_spawn_render_ring_function = bow[\spawn_render_ring_function];
var render_ring = bob_spawn_render_ring_function.value();
// TODO arc_common - finish

var hi_level = 15;
var lo_level = 5; // TODO: 4 in lua

var init = { |conf|
	var visual_values = conf[\visual_values] ? ();
	var ui_spec = conf[\ui_spec]; // TODO: ui_spec/pages can be made optional

	var globals = conf[\globals];
	var screen_global = globals[\screen] ?? { Error("screen global is required").throw };
	var params_global = globals[\params] ?? { Error("params global is required").throw };

	var refresh_rate = ui_spec[\refresh_rate] ?? { Error("refresh rate is required").throw };

	var script_context = (
		globals: (
			screen: screen_global,
			params: params_global,
		),
		ui_spec: ui_spec,
		state: (
			current_page: 0,
			fine: false,
			prev_held: false,
			next_held: false,
			target_page: nil,
			page_trans_div: nil,
			page_trans_frames: nil,
			focus: nil,
			active: nil,
			mouse_move_pos: nil,
			mouse_down_pos: nil,
			visual_values: visual_values,
		)
	);

	init_ui.value(script_context);

	script_context;
};

// TODO: move to script bacause of ui_dirty flag
var add_params = { |param_specs, params_global|
	param_specs.do { |param_spec|
		params_global.add_(
			(
				type: param_spec[\type],
				id: param_spec[\id],
				name: param_spec[\narrow_name] ? param_spec[\name],
				controlspec: param_spec[\controlspec],
				formatter: param_spec[\narrow_formatter] ? param_spec[\formatter],
				action: { |value|
					param_spec[\action].value(value);
					// TODO set_ui_dirty.value(script_context);
				}
			)
		);
	};
};

var init_ui = { |script_context|
	var globals = script_context[\globals];
	var params_global = globals[\params];
	var screen_global = globals[\screen];

	var ui_spec = script_context[\ui_spec];

	calculate_ui_label_widths.value(params_global, screen_global, ui_spec[\pages]);
};

var calculate_ui_label_widths = { |params_global, screen_global, pages|
	screen_global.font_size_(16);
	pages.do { |page, index|
		page.do { |page_param|
			var label = params_global.get_name_(page_param[\id]);
			page_param[\label_width] = screen_global.text_extents_(label) - 2; // TODO: label_width ? name_width ?
		};
	};
};

var redraw = { |params_global, screen_global, pages, state, show_event_indicator| // TODO: inject screen, params globals
	var visual_values_dict = state[\visual_values]; // TODO
	var current_page = state[\current_page];
	var fine = state[\fine];
	var prev_held = state[\prev_held];
	var next_held = state[\next_held];
	var focus = state[\focus];

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
			screen_global.move_(enc1_x, enc1_y);
			screen_global.level_(lo_level);
			screen_global.text_("LEVEL");
		};
		var draw_current_value = {
			var the_value = round(params_global.get_raw_("output_level")*100).asInteger.asString;
			var value_x = enc1_x + screen_global.text_extents_("LEVEL") + 3;
			var value_y = enc1_y;
			var value_width = screen_global.text_extents_(the_value);
			var value_bounds = Rect(value_x, value_y-12, value_width, 12);
			screen_global.move_(value_x, value_y);
			if (focus == 'enc1') {
				screen_global.level_((hi_level+lo_level)/2);
			} {
				screen_global.level_(hi_level);
			};
			screen_global.text_(the_value);
		};
		draw_label.value;
		draw_current_value.value;
	};

	var draw_event_flash_widget = {
		screen_global.level_(lo_level);
		screen_global.rect_(122, enc1_y-7, 5, 5);
		screen_global.fill_();
	};

	var draw_bullet = { |x, y, level|
		screen_global.level_(level);
		screen_global.rect_(x, y, 2, 2);
		screen_global.fill_();
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
	var draw_page_param = { |page, param_index, x, y, focussed|
		var page_param = pages[page][param_index];
		var draw_label = {
			var label = params_global.get_name_(page_param[\id]);
			screen_global.move_(x, y);
			screen_global.level_(lo_level);
			screen_global.text_(label); // TODO
		};
		var draw_current_value = {
			var the_value = params_global.string_(page_param[\id]);
			var value_x = x;
			var value_y = y + 12;
			var value_width = screen_global.text_extents_(the_value);
			var value_bounds = Rect(value_x, value_y-12, value_width, 12);
			screen_global.move_(value_x, value_y);
			if (focussed) {
				screen_global.level_((hi_level+lo_level)/2);
			} {
				screen_global.level_(hi_level);
			};
			screen_global.text_(the_value);

		};
		var draw_widget = {
			var widget_x = x + 1;
			var widget_y = y + 14;
			var id = page_param[\id];
			var visual_values = visual_values_dict[id];
			var raw_value = params_global.get_raw_(id);

			if (visual_values.notNil) {
				draw_visual_values.value(widget_x, widget_y, page_param[\label_width], visual_values);
			};

			draw_value.value(widget_x, widget_y, translate.value(raw_value, page_param[\label_width]), hi_level);
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

		draw_page_param.value(
			left,
			0,
			enc2_x-pixel_ofs,
			enc2_y,
			focus == 'enc2' // TODO: on transition consider this unfocussed?
		); // TODO: zero based


		if (left != right) {
			draw_page_param.value(
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

		draw_page_param.value(
			left,
			1,
			enc3_x-pixel_ofs,
			enc3_y,
			focus == 'enc3' // TODO: on transition consider this unfocussed?
		); // TODO: zero based

		if (left != right) {
			draw_page_param.value(
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

		screen_global.level_(lo_level);
		screen_global.rect_(x, y, width, height);
		screen_global.fill_();
	};

	var draw_key2key3_widget = {
		screen_global.move_(key2_x+42, key2_y);
		screen_global.level_(hi_level);
		screen_global.text_("FN");
	};

	var draw_key_widget = { |widget_x, widget_y, text, key_held, focussed|
		screen_global.move_(widget_x, widget_y);
		if (key_held and: fine.not) {
			screen_global.level_(hi_level);
		} {
			if (focussed) {
				screen_global.level_((hi_level+lo_level)/2);
			} {
				screen_global.level_(lo_level);
			};
		};
		screen_global.text_(text);
	};

	var draw_key2_widget = {
		draw_key_widget.value(key2_x, key2_y, "PREV", prev_held, focus == 'key2');
	};

	var draw_key3_widget = {
		draw_key_widget.value(key3_x, key3_y, "NEXT", next_held, focus == 'key3');
	};

	screen_global.clear_(); // TODO: do this in redraw() ?

	screen_global.font_size(16);

	draw_enc1_widget.value();

	if (show_event_indicator) {
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

	screen_global.update_();
};

var enc = { |script_context, n, delta|
	var params_global = script_context[\globals][\params];
	var fine = script_context[\state][\fine];
	var d;
	if (fine) {
		d = delta/5
	} {
		d = delta
	};
	if (n == 1) {
		params_global.delta_("output_level", d);
		// TODO set_ui_dirty.value(script_context);
	} {
		params_global.delta_(get_param_id_for_current_page.value(script_context, n-2), d); // TODO: zero based
	};
};

var key = { |script_context, n, z|
	var ui_spec = script_context[\ui_spec];
	var pages = ui_spec[\pages];

	var state = script_context[\state];
	var target_page = state[\target_page];
	var page;

	var ui_dirty = false;

	if (target_page.notNil) {
		page = target_page;
	} {
		page = get_active_page.value(script_context);
	};

	case
	{n == 2} {
		if (z == 1) {
			page = page - 1;
			if (page < 0) { // TODO: zero based indexing
				page = pages.size-1; // TODO: zero based indexing
			};

			transition_to_page.value(script_context, page);

			state[\prev_held] = true;
		} {
			state[\prev_held] = false;
		};
		ui_dirty = true;
	}
	{n == 3} {
		if (z == 1) {
			page = page + 1;
			if (page > (pages.size-1)) { // TODO: zero based indexing
				page = 0; // TODO: zero based indexing
			};

			transition_to_page.value(script_context, page);

			state[\next_held] = true;
		} {
			state[\next_held] = false
		};
		ui_dirty = true;
	};

	state[\fine] = (state[\prev_held] and: state[\next_held]);
	ui_dirty;
};

var set_page = { |script_context, page|
	script_context[\state][\current_page] = page;
};

var get_active_page = { |script_context|
	round(script_context[\state][\current_page]);
};

var get_param_id_for_current_page = { |script_context, n|
	var ui_spec = script_context[\ui_spec];
	var pages = ui_spec[\pages];

	var page = get_active_page.value(script_context);
	pages[page][n].id;
};

var transition_to_page = { |script_context, page| // TODO: inject refresh_rate
	var state = script_context[\state];
	var ui_spec = script_context[\ui_spec];
	var refresh_rate = ui_spec[\refresh_rate];
	var current_page = state[\current_page];

	state[\target_page] = page;
	state[\page_trans_frames] = refresh_rate/5;
	state[\page_trans_div] = (state[\target_page] - current_page) / state[\page_trans_frames];
};

var load_settings = {
	"load_settings not implemented".inform; // TODO
};

var save_settings = {
	"save_settings not implemented".inform; // TODO
};

// TODO arc_common - start
var render_arc = { |script_context, my_arc|
	var params_global = script_context[\globals][\params];
	var state = script_context[\state];

	var ui_spec = script_context[\ui_spec];
	var pages = ui_spec[\pages];

	var page = pages[get_active_page.value(script_context)];

	var param1_id = get_param_id_for_current_page.value(script_context, 0); // TODO: zero-based
	var param2_id = get_param_id_for_current_page.value(script_context, 1); // TODO: zero-based

	var visual_values_dict = state[\visual_values]; // TODO

	var visual_values1_dict = visual_values_dict[param1_id];
	var visual_values2_dict = visual_values_dict[param2_id];

	var visual_values1, visual_values2;

	if (visual_values1_dict.notNil) {
		visual_values1 = visual_values1_dict[\content];
	};

	if (visual_values2_dict.notNil) {
		visual_values2 = visual_values2_dict[\content];
	};

	draw_arc.value(
		my_arc,
		params_global.get_raw_(param1_id), // TODO: zero-based indexing
		visual_values1,
		params_global.get_raw_(param2_id), // TODO: zero-based indexing
		visual_values2
	);
};

var draw_arc = { |my_arc, value1, visual_values1, value2, visual_values2|
	var draw_ring = { |ring, value, visual_values|
		var led_levels = render_ring.value(value, visual_values);
		led_levels.do { |led_level, i|
			my_arc.led_(ring, i+1, led_level); // TODO: zero to one based
		};
	};
	my_arc.all_(1, 0);
	my_arc.all_(2, 0);
	draw_ring.value(1, value1, visual_values1);
	draw_ring.value(2, value2, visual_values2);
};
// TODO arc_common - finish

var cleanup = { |settings_file|
	save_settings.value(settings_file);
	// params_global.write_(); // TODO
};

var load_settings_and_params = { |settings_file, params_global|
	load_settings.value(settings_file);
	// params_global.read_(); // TODO
	params_global.bang_();
};

var mouse = { |script_context, what ... args|
	var globals = script_context[\globals];
	var screen_global = globals[\screen];
	var params_global = globals[\params];

	var ui_spec = script_context[\ui_spec];
	var pages = ui_spec[\pages];

	var state = script_context[\state];


	case
	{ what == "leave" } {
		mouse_leave.value(state);
	}
	{ what == "over" } {
		var x = args[0], y = args[1];
		mouse_over.value(params_global, screen_global, pages, state, x, y);
	}
	{ what == "down" } {
		var x = args[0], y = args[1];
		mouse_down.value(script_context, x, y);
	}
	{ what == "move" } {
		var x = args[0], y = args[1];
		mouse_move.value(script_context, x, y);
	}
	{ what == "up" } {
		var x = args[0], y = args[1];
		mouse_up.value(script_context, x, y);
	}
	{ what == "wheel" } {
		var x_delta = args[0], y_delta = args[1];
		mouse_wheel.value(script_context, x_delta, y_delta);
	}
};

var mouse_leave = { |state|
	state[\focus] = nil;
};

var mouse_over = { |params_global, screen_global, pages, state, x, y|
	var mouse_over_pos = x@y;
	update_focus.value(params_global, screen_global, pages, state, mouse_over_pos); // TODO: only if mouse is not pressed(?)
};

var mouse_down = { |script_context, x, y|
	var state = script_context[\state];
	var focus = state[\focus];
	state[\mouse_down_pos] = x@y;

	case
	{ focus == 'key2' } {
		key.value(script_context, 2, 1); // TODO: better handled not using key?
	}
	{ focus == 'key3' } {
		key.value(script_context, 3, 1); // TODO: better handled not using key?
	};

	state[\active] = focus;
};

var mouse_move = { |script_context, x, y|
	var state = script_context[\state];
	var active = state[\active];
	var mouse_move_delta;

	var prev_mouse_move_pos = state[\mouse_move_pos];
	state[\mouse_move_pos] = x@y;
	mouse_move_delta = (prev_mouse_move_pos ? state[\mouse_down_pos]) - (x@y);
	if (mouse_move_delta.y != 0) {
		case
		{active == 'enc1'} {
			enc.value(script_context, 1, mouse_move_delta.y); // TODO: better handled not using enc?
		}
		{active == 'enc2'} {
			enc.value(script_context, 2, mouse_move_delta.y); // TODO: better handled not using enc?
		}
		{active == 'enc3'} {
			enc.value(script_context, 3, mouse_move_delta.y); // TODO: better handled not using enc?
		};
	};
};

var mouse_up = { |script_context, x, y|
	var state = script_context[\state];

	var globals = script_context[\globals];
	var screen_global = globals[\screen];
	var params_global = globals[\params];

	var ui_spec = script_context[\ui_spec];
	var pages = ui_spec[\pages];

	state[\mouse_move_pos] = nil;

	case
	{ state[\active] == 'key2' } {
		key.value(script_context, 2, 0); // TODO: better handled not using key?
	}
	{ state[\active] == 'key3' } {
		key.value(script_context, 3, 0); // TODO: better handled not using key?
	};

	state[\active] = nil;

	update_focus.value(params_global, screen_global, pages, state, x@y);
};

var mouse_wheel = { |script_context, x_delta, y_delta|
	var state = script_context[\state];
	var focus = state[\focus];

	if (y_delta != 0) {
		case
		{focus == 'enc1'} {
			enc.value(script_context, 1, y_delta*(-1)); // TODO: better handled not using enc?
		}
		{focus == 'enc2'} {
			enc.value(script_context, 2, y_delta*(-1)); // TODO: better handled not using enc?
		}
		{focus == 'enc3'} {
			enc.value(script_context, 3, y_delta*(-1)); // TODO: better handled not using enc?
		};
	};
};

var update_focus = { |params_global, screen_global, pages, state, pos|
	var current_page = state[\current_page];

	case
	{ over_enc1_value.value(params_global, screen_global, pos) } { // TODO: refactor out over_enc1_value
		state[\focus] = 'enc1';
	}
	{ over_enc2_value.value(params_global, screen_global, pages, current_page, pos) } { // TODO: refactor out over_enc2_value
		state[\focus] = 'enc2';
	}
	{ over_enc3_value.value(params_global, screen_global, pages, current_page, pos) } { // TODO: refactor out over_enc3_value
		state[\focus] = 'enc3';
	}
	{ over_key2.value(screen_global, pos) } { // TODO: refactor out over_key2
		state[\focus] = 'key2';
	}
	{ over_key3.value(screen_global, pos) } { // TODO: refactor out over_key2
		state[\focus] = 'key3';
	}
	{ true } {
		state[\focus] = nil;
	};
};

var over_enc1_value = { |params_global, screen_global, pos|
	var bounds = get_enc1_value_bounds.value(params_global, screen_global);
	bounds.contains(pos);
};

var over_enc2_value = { |params_global, screen_global, pages, current_page, pos|
	var bounds = get_enc2_value_bounds.value(params_global, screen_global, pages, current_page);
	bounds.contains(pos);
};

// TODO: DRY
var over_key2 = { |screen_global, pos|
	var key2_x = 1;
	var key2_y = 63;
	var text_width = screen_global.text_extents_("PREV");
	var bounds = Rect(key2_x, key2_y-12, text_width, 10);
	bounds.contains(pos);
};

// TODO: DRY
var over_key3 = { |screen_global, pos|
	var key2_x = 1;
	var key2_y = 63;
	var key3_x = key2_x+65;
	var key3_y = key2_y;
	var text_width = screen_global.text_extents_("NEXT");
	var bounds = Rect(key3_x, key3_y-12, text_width, 10);
	bounds.contains(pos);
};

// TODO: DRY
var get_enc1_value_bounds = { |params_global, screen_global|
	var enc1_x = 1;
	var enc1_y = 12;
	var the_value = round(params_global.get_raw_("output_level")*100).asString; // TODO: use formatter instead of raw
	var value_x = enc1_x + screen_global.text_extents_("LEVEL") + 3;
	var value_y = enc1_y;
	var value_width = screen_global.text_extents_(the_value);
	Rect(value_x, value_y-12, value_width, 12);
};

var over_enc3_value = { |params_global, screen_global, pages, current_page, pos|
	var bounds = get_enc3_value_bounds.value(params_global, screen_global, pages, current_page);
	bounds.contains(pos);
};

// TODO: DRY
var get_enc2_value_bounds = { |params_global, screen_global, pages, current_page|
	var enc2_x = 10; // TODO: DRY
	var enc2_y = 29;

	var left = floor(current_page);
	// var right = ceil(current_page);
	var offset = current_page - left;
	var pixel_ofs = round(offset*128);

	get_enc2_enc3_value_bounds.value(params_global, screen_global, pages, left, 0, enc2_x-pixel_ofs, enc2_y); // TODO: zero based
};

// TODO: DRY
var get_enc3_value_bounds = { |params_global, screen_global, pages, current_page|
	var enc2_x = 10; // TODO: DRY
	var enc2_y = 29;
	var enc3_x = enc2_x + 65;
	var enc3_y = enc2_y;

	var left = floor(current_page);
	//var right = ceil(current_page);
	var offset = current_page - left;
	var pixel_ofs = round(offset*128);

	get_enc2_enc3_value_bounds.value(params_global, screen_global, pages, left, 1, enc3_x-pixel_ofs, enc3_y); // TODO: zero based
};

var get_enc2_enc3_value_bounds = { |params_global, screen_global, pages, page, param_index, x, y|
	var page_param = pages[page][param_index];
	var the_value = params_global.string_(page_param[\id]);
	var value_x = x;
	var value_y = y + 12;
	var value_width = screen_global.text_extents_(the_value);
	Rect(value_x, value_y-12, value_width, 10);
};

var module = IdentityDictionary[
	\init -> init,
	\redraw -> redraw,
	\enc -> enc,
	\key -> key,
	\cleanup -> cleanup,
	\get_active_page -> get_active_page,
	\mouse -> mouse,
	\add_params -> add_params,
	\load_settings_and_params -> load_settings_and_params,
	\render_arc -> render_arc,
	\get_param_id_for_current_page -> get_param_id_for_current_page
];

module
)
