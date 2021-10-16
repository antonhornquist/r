(
// TODO: remove single character variables which won't work in SC
var include_relative = { |relative_path|
	var path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ relative_path).standardizePath;
	if (File.exists(path)) {
		this.executeFile(path);
	} {
		Error("include_relative: file % does not exist".format(path.quote)).throw;
	};
};

var norns_engine_tester = include_relative.value("../../r/util/norns_engine_tester.scd");
var start_script = norns_engine_tester['start_script'];
var script_name = PathName(thisProcess.nowExecutingPath).fileNameWithoutExtension;

start_script.value(script_name) {
	var ack = include_relative.value("lib/ack.scd");
	var ack_add_params = ack[\add_params];

	var specs = include_relative.value("lib/specs.scd");
	var arc_led_x_spec = specs[\arc_led_x_spec];
	var arc_led_l_spec = specs[\arc_led_l_spec];

	var ui_dirty = false;

	// arc

	var arc_device;

	// grid

	var grid_device;
	var grid_width;

	var update_grid_width = {
		if (grid_device.device_.notNil) {
			if (grid_width != grid_device.cols_) {
				grid_width = grid_device.cols_;
			};
		};
	};

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

	var refresh_ui = {
		update_event_indicator.value();

		update_grid_width.value();

		if (ui_dirty) {
			var refresh_grid_button = { |x, y|
				if (cutting_is_enabled.value() and: (y == 8)) {
					if (x == playpos) {
						grid_device.led_(x, y, playpos_level);
					} {
						grid_device.led_(x, y, clear_level);
					};
				} {
					case
					{trig_is_set.value(~params.get_("pattern"), x, y)} {
						grid_device.led_(x, y, trig_level)
					}
					{ x == playpos } {
						grid_device.led_(x, y, playpos_level)
					}
					{ true } {
						grid_device.led_(x, y, clear_level)
					}
				}
			};

			var refresh_grid_column = { |x|
				(1..num_tracks).do { |y|
					refresh_grid_button.value(x, y)
				}
			};

			var refresh_grid = {
				(1..steps_per_pattern).do { |stepnum|
					refresh_grid_column.value(stepnum)
				}
			};

			refresh_grid.value(); // TODO: naming
			grid_device.refresh_();

			arc_device.all_(1, 0);
			arc_device.all_(2, 0);
			arc_device.led_(1, arc_led_x_spec.map(~params.get_raw_("tempo")), arc_led_l_spec.maxval);
			arc_device.led_(2, arc_led_x_spec.map(~params.get_raw_("swing_amount")), arc_led_l_spec.maxval);
			arc_device.refresh_();

			~redraw.value();

			ui_dirty = false;
		};
	};

	var num_patterns = 99;
	var steps_per_pattern = 16;
	var num_tracks = 8;

	var pattern_file = "step.data";

	var trig_level = 15;
	var playpos_level = 7;
	var clear_level = 0;

	var tempo_spec = ControlSpec.new(20, 300, 'lin', 0.1, 60, "BPM");
	var swing_amount_spec = ControlSpec.new(0, 100, 'lin', 0.1, 0, "%");

	var playing = false;
	var queued_playpos;
	var playpos = 0;
	var sequencer_metro;

	var ppqn = 24;
	var ticks_to_next;
	var odd_ppqn;
	var even_ppqn;

	var trigs = Array.fill(num_patterns*steps_per_pattern*num_tracks);

	var hi_level = 15;
	var lo_level = 4;

	var enc1_x = 1; // TODO
	var enc1_y = 13; // TODO

	var enc2_x = 8;
	var enc2_y = 32;

	var enc3_x = enc2_x+50;
	var enc3_y = enc2_y;

	var key2_x = 1; // TODO
	var key2_y = 64; // TODO

	var key3_x = key2_x+45;
	var key3_y = key2_y;

	var focus;
	var mode = 'main'; // 'main, 'pattern', 'params'
	var key1_held = false;
	var key2_held = false;
	var key3_held = false;

	var params_ui_cursor_step = 20;
	var params_ui_cursor = 1 * params_ui_cursor_step;

	var cutting_is_enabled = {
		~params.get_("last_row_cuts") == 2
	};

	var set_trig = { |patternno, stepnum, tracknum, value|
		var index = get_trigs_index.value(patternno, stepnum, tracknum);
		trigs[index] = value;
	};

	var trig_is_set = { |patternno, stepnum, tracknum|
		var index = get_trigs_index.value(patternno, stepnum, tracknum);
		trigs[index]
	};

	var get_trigs_index = { |patternno, stepnum, tracknum|
		((patternno-1)*steps_per_pattern*num_tracks) + ((tracknum-1)*steps_per_pattern) + (stepnum-1)
	};

	var init_trigs = {
		(1..num_patterns).do { |patternno|
			(1..steps_per_pattern).do { |stepnum|
				(1..num_tracks).do { |tracknum|
					set_trig.value(patternno, stepnum, tracknum, false);
				}
			}
		}
	};

	var get_pattern_length = {
		if (~params.get_("pattern_length") == 1) {
			8
		} {
			16
		};
	};

	var set_pattern_length = { |pattern_length|
		var opt;
		if (pattern_length == 8) {
			opt = 1
		} {
			opt = 2
		};
		~params.set__("pattern_length", opt)
	};

	var save_patterns = {
		var filename = ~norns.state.data ++ pattern_file;
		File.use(filename.standardizePath, "w+") { |file|
			(1..num_patterns).do { |patternno|
				(1..num_tracks).do { |tracknum|
					(1..steps_per_pattern).do { |stepnum|
						var int;
						if (trig_is_set.value(patternno, stepnum, tracknum)) {
							int = 1
						} {
							int = 0
						};
						file.write(int.asString ++ "\n");
					};
				};
			};
		};
	};

	var load_patterns = {
		var filename = ~norns.state.data ++ pattern_file;
		if (File.exists(filename.standardizePath)) {
			File.use(filename.standardizePath, "r") { |file|
				(1..num_patterns).do { |patternno|
					(1..num_tracks).do { |tracknum|
						(1..steps_per_pattern).do { |stepnum|
							var line = file.getLine();
							if (line.notNil) {
								set_trig.value(patternno, stepnum, tracknum, line.stripWhiteSpace == "1");
							} {
								Error("file % has invalid pattern file format".format(filename)).throw;
							};
						};
					};
				};
			};
		};
	};  

	var tick = {
		if (queued_playpos.notNil and: (~params.get_("cut_quant") == 1)) {
			ticks_to_next = 0;
		};

		if ((ticks_to_next.isNil) or: (ticks_to_next == 0)) {
			var ts = Array.fill(num_tracks);
			var previous_playpos = playpos;
			if (queued_playpos.notNil) {
				playpos = queued_playpos;
				queued_playpos = nil;
			} {
				playpos = playpos + 1;
				if (playpos > get_pattern_length.value()) {
					playpos = 1;
				};
			};
			(1..num_tracks).do { |tracknum|
				if (trig_is_set.value(~params.get_("pattern"), playpos, tracknum) and: (cutting_is_enabled.value() and: (tracknum == (num_tracks))).not) {
					ts[tracknum-1] = 1;
				} {
					ts[tracknum-1] = 0;
				}
			};
			[\engine, \multiTrig_, ts[0], ts[1], ts[2], ts[3], ts[4], ts[5], ts[6], ts[7]].debug;
			~engine.multiTrig_(ts[0], ts[1], ts[2], ts[3], ts[4], ts[5], ts[6], ts[7]);

			if (playpos.even) {
				ticks_to_next = even_ppqn;
			} {
				ticks_to_next = odd_ppqn;
			};
			ui_dirty = true;
		};

		if (~grid.device_.notNil) {
			var current_grid_width = grid_width;

			if (get_pattern_length.value != current_grid_width) {
				set_pattern_length.value(current_grid_width);
			};
		};

		ticks_to_next = ticks_to_next - 1;
	};

	var update_sequencer_metro_time = {
		sequencer_metro.time = 60/~params.get_("tempo")/ppqn/~params.get_("beats_per_pattern");
	};

	var update_even_odd_ppqn = { |swing_amount|
		var swing_ppqn = ppqn*swing_amount/100*0.75;
		even_ppqn = round(ppqn-swing_ppqn);
		odd_ppqn = round(ppqn+swing_ppqn);
	};

	var init_sequencer_metro = {
		sequencer_metro = ~metro.init_();
		update_sequencer_metro_time.value();
		sequencer_metro.event = tick;
	};

	var init_params = {
		~params.add_(
			(
				type: "option",
				id: "pattern_length",
				name: "Pattern Length",
				options: [8, 16],
				default: 2
			)
		);

		~params.add_(
			(
				type: "number",
				id: "pattern",
				name: "Pattern",
				min: 1,
				max: num_patterns,
				default: 1,
				action: {
					ui_dirty = true;
				}
			)
		);

		~params.add_(
			(
				type: "option",
				id: "last_row_cuts",
				name: "Last Row Cuts",
				options: ["No", "Yes"],
				default: 1
			)
		);

		~params.add_(
			(
				type: "option",
				id: "cut_quant",
				name: "Quantize Cutting",
				options: ["No", "Yes"],
				default: 1
			)
		);

		~params.add_(
			(
				type: "number",
				id: "beats_per_pattern",
				name: "Beats Per Pattern",
				min: 1,
				max: 8,
				default: 4,
				action: {
					update_sequencer_metro_time.value();
				}
			)
		);

		~params.add_(
			(
				type: "control",
				id: "tempo",
				name: "Tempo",
				controlspec: tempo_spec,
				action: {
					update_sequencer_metro_time.value();
					ui_dirty = true;
				}
			)
		);

		~params.add_(
			(
				type: "control",
				id: "swing_amount",
				name: "Swing Amount",
				controlspec: swing_amount_spec,
				action: { |val|
					update_even_odd_ppqn.value(val);
					ui_dirty = true;
				}
			)
		);

		~params.add_separator_();

		ack_add_params.value();
	};

	var init_60_fps_ui_refresh_metro = {
		var ui_refresh_metro = ~metro.init_();
		ui_refresh_metro.event = refresh_ui;
		ui_refresh_metro.time = 1/60;
		ui_refresh_metro.start_();
	};

	var init_ui = {
		arc_device = ~arc.connect_();

		arc_device[\delta] = { |n, delta| // not .delta notation to suppress self argument?
			flash_event.value();
			case
			{ mode == 'main' } {
				case
				{n == 1} {
					var val = ~params.get_raw_("tempo");
					~params.set_raw_("tempo", val+(delta/500));
				}
				{n == 2} {
					var val = ~params.get_raw_("swing_amount");
					~params.set_raw_("swing_amount", val+(delta/500));
				}
			}
			{ mode == 'params' } {
				case
				{n == 1} {
					params_ui_cursor = ((params_ui_cursor + delta) max: params_ui_cursor_step) min: (~params[\params].size*params_ui_cursor_step);
				}
				{n == 2} {
					var params_ui_cursor_unstepped = (params_ui_cursor/params_ui_cursor_step).round;
					var param = ~params[\params][params_ui_cursor_unstepped-1];
/*
TODO
					var val = param.get_raw_();
					param.set_raw_(val+(delta/500));
*/
					param.delta_(delta);
				};
				ui_dirty = true;
			};
		};

		grid_device = ~grid.connect_();

		grid_device[\key] = { |x, y, state| // not .key notation to suppress self argument? // TODO: x, y are single character
			flash_event.value();
			if (state == 1) {
				if (cutting_is_enabled.value() and: (y == 8)) { // TODO: y == 8 should be y == 7 everywhere
					queued_playpos = x;
					ui_dirty = true; // TODO: not correct
				} {
					set_trig.value(
						~params.get_("pattern"),
						x,
						y,
						trig_is_set.value(~params.get_("pattern"), x, y).not
					);
					ui_dirty = true;
				}
			};
		};

		init_60_fps_ui_refresh_metro.value();
	};

	var get_play_label = {
		if (playing) {
			"PLAY " ++ playpos; // TODO: sometimes prints 0!?
		} {
			"PLAY";
		};
	};

	var active, mouse_move_pos, mouse_down_pos, mouse_move_delta;

	var mouse_leave = { |script_context|
		var prev_focus = focus;
		focus = nil;
		if (prev_focus != focus) {
			ui_dirty = true;
		};
	};
	
	var mouse_over = { |x, y|
		var prev_focus = focus;
	
		var mouse_over_pos = x@y;
	
		update_focus.value(mouse_over_pos); // TODO: only if mouse is not pressed(?)
	
		if (prev_focus != focus) {
			ui_dirty = true;
		};
	};

	var mouse_down_pattern_ui_action = { |x, y, buttonnum|
		case
		{ focus.notNil } {
			var patternno = ~params.get_("pattern");
			var trig_in_focus = focus[\pos];
			if (cutting_is_enabled.value() and: (trig_in_focus.y == num_tracks)) {
				queued_playpos = trig_in_focus.x;
				ui_dirty = true; // TODO: not correct
			} {
				set_trig.value(patternno, trig_in_focus.x, trig_in_focus.y, trig_is_set.value(patternno, trig_in_focus.x, trig_in_focus.y).not);
			};
		}
		{ true } {
		}
	};

	var mouse_down_main_ui_action = { |x, y, buttonnum|
		case
		{ focus == 'key2' } {
			~key.value(2, 1); // TODO: better handled not using key?
		}
		{ focus == 'key3' } {
			~key.value(3, 1); // TODO: better handled not using key?
		};
	};
	
	var mouse_down = { |x, y, buttonnum|
		var prev_active = active;
		mouse_down_pos = x@y;
	
		case
		{ mode == 'main' } {
			mouse_down_main_ui_action.value(x, y, buttonnum);
		}
		{ mode == 'pattern' } {
			mouse_down_pattern_ui_action.value(x, y, buttonnum);
		}
		{ mode == 'params' } {
			// TODO mouse_down_params_ui_action.value(x, y, buttonnum);
		};
	
		active = focus;
	
		if (prev_active != active) {
			ui_dirty = true;
		};
	};

	var mouse_drag = { |x, y, drag|
		if (mode == 'pattern') {
			var trig;
			trig = get_trig_mouse_hovers_over.value(x@y);
			case
			{ trig.notNil } {
				~params.set__(trig.y.asString++"_sample", drag)
			}
			{ true } {
				focus = nil;
			};
			ui_dirty = true;
		};
	};

	var mouse_move = { |x, y|
		var mouse_move_delta;
	
		var prev_mouse_move_pos = mouse_move_pos;
		mouse_move_pos = x@y;
		mouse_move_delta = (prev_mouse_move_pos ? mouse_down_pos) - (x@y);
		if (mouse_move_delta.y != 0) {
			case
			{active == 'enc1'} {
				~enc.value(1, mouse_move_delta.y); // TODO: better handled not using enc?
			}
			{active == 'enc2'} {
				~enc.value(2, mouse_move_delta.y); // TODO: better handled not using enc?
			}
			{active == 'enc3'} {
				~enc.value(3, mouse_move_delta.y); // TODO: better handled not using enc?
			};
		};
	};
	
	var mouse_up = { |x, y|
		var prev_active = active;
	
		mouse_move_pos = nil;
	
		case
		{ active == 'key2' } {
			~key.value(2, 0); // TODO: better handled not using key?
		}
		{ active == 'key3' } {
			~key.value(3, 0); // TODO: better handled not using key?
		};
	
		active = nil;
	
		update_focus.value(x@y);
	
		if (prev_active != active) {
			ui_dirty = true;
		};
	};
	
	var mouse_wheel = { |x_delta, y_delta|
		if (y_delta != 0) {
			case
			{focus == 'enc1'} {
				~enc.value(1, y_delta*(-1)); // TODO: better handled not using enc?
			}
			{focus == 'enc2'} {
				~enc.value(2, y_delta*(-1)); // TODO: better handled not using enc?
			}
			{focus == 'enc3'} {
				~enc.value(3, y_delta*(-1)); // TODO: better handled not using enc?
			};
		};
	};
	
	var get_trig_mouse_hovers_over = { |mouse_pos|
		var trig;
		(1..steps_per_pattern).do { |stepnum|
			(1..num_tracks).do { |tracknum|
				var trig_pos = calculate_trig_position.value(tracknum, stepnum);
				var left = trig_pos.x - additional_extent_x;
				var right = trig_pos.x + trig_width + additional_extent_x;
				var top = trig_pos.y - additional_extent_y;
				var bottom = trig_pos.y + trig_height + additional_extent_y;
				if (
					(left <= mouse_pos.x) and:
					(top <= mouse_pos.y) and:
					(mouse_pos.x <= right) and:
					(mouse_pos.y <= bottom)
				) {
					trig = stepnum@tracknum;
				}
			};
		};
		trig;
	};

	var construct_trig_symbol = { |tracknum, stepnum|
		(type: \trig, pos: stepnum@tracknum)
	};

	var update_pattern_ui_focus = { |pos|
		var trig;
		trig = get_trig_mouse_hovers_over.value(pos);
		case
		{ trig.notNil } {
			focus = construct_trig_symbol.value(trig.y, trig.x);
		}
		{ true } {
			focus = nil;
		};
	};

	var update_main_ui_focus = { |pos|
		case
		{ over_enc1_value.value(pos) } { // TODO: refactor out over_enc1_value
			focus = 'enc1';
		}
		{ over_enc2_value.value(pos) } { // TODO: refactor out over_enc2_value
			focus = 'enc2';
		}
		{ over_enc3_value.value(pos) } { // TODO: refactor out over_enc3_value
			focus = 'enc3';
		}
		{ over_key2.value(pos) } { // TODO: refactor out over_key2
			focus = 'key2';
		}
		{ over_key3.value(pos) } { // TODO: refactor out over_key2
			focus = 'key3';
		}
		{ true } {
			focus = nil;
		};
	};

	var update_focus = { |pos|
		case
		{ mode == 'main' } {
			update_main_ui_focus.value(pos);
		}
		{ mode == 'pattern' } {
			update_pattern_ui_focus.value(pos);
		};
	};
	
	var over_enc1_value = { |pos|
		var bounds = get_enc1_value_bounds.value();
// TODO [bounds, pos].debug('contains');
		bounds.contains(pos);
	};
	
	var over_enc2_value = { |pos|
		var bounds = get_enc2_value_bounds.value();
		bounds.contains(pos);
	};
	
	// TODO: DRY
	var over_key2 = { |pos|
		var key2_x = 1;
		var key2_y = 63;
		var text_width = ~screen.text_extents_("STOP"); // TODO: do not hard code label
		var bounds = Rect(key2_x, key2_y-12, text_width, 10);
		bounds.contains(pos);
	};
	
	// TODO: DRY
	var over_key3 = { |pos|
		var key2_x = 1;
		var key2_y = 63;
		var key3_x = key2_x+45;
		var key3_y = key2_y;
		var text_width = ~screen.text_extents_(get_play_label.value());
		var bounds = Rect(key3_x, key3_y-12, text_width, 10);
		bounds.contains(pos);
	};
	
	// TODO: DRY
	var get_enc1_value_bounds = {
		var enc1_x = 1;
		var enc1_y = 12;
		var the_value = round(/* TODO ~params.get_raw_("output_level") */ 0.5 *100).asString; // TODO: introduce engine specific output level
		var value_x = enc1_x + ~screen.text_extents_("LEVEL") + 3;
		var value_y = enc1_y;
		var value_width = ~screen.text_extents_(the_value);
		Rect(value_x, value_y-12, value_width, 12);
	};
	
	var over_enc3_value = { |pos|
		var bounds = get_enc3_value_bounds.value();
		bounds.contains(pos);
	};
	
	// TODO: DRY
	var get_enc2_value_bounds = {
		var enc2_x = 8;
		var enc2_y = 32;
	
		var value_x = enc2_x;
		var value_y = enc2_y + 12;
		var the_value = ~params.get_("tempo").asString;
		var value_width = ~screen.text_extents_(the_value);
		Rect(value_x, value_y-12, value_width, 10);
	};
	
	// TODO: DRY
	var get_enc3_value_bounds = {
		var enc2_x = 8;
		var enc2_y = 32;
		var enc3_x = enc2_x + 50;
		var enc3_y = enc2_y;
	
		var value_x = enc3_x;
		var value_y = enc3_y + 12;
		var the_value = ~params.get_("swing_amount").asString ++ "%";
		var value_width = ~screen.text_extents_(the_value);
		Rect(value_x, value_y-12, value_width, 10);
	};
	
	var redraw_event_flash_widget = {
		~screen.level_(lo_level);
		~screen.rect_(122, enc1_y-7, 5, 5);
		~screen.fill_();
	};

	var redraw_main_ui = {
		var redraw_enc1_widget = {
			~screen.move_(enc1_x, enc1_y);
			~screen.level_(lo_level);
			~screen.text_("LEVEL");
   			~screen.move_(enc1_x+45, enc1_y);
			if (focus == 'enc1') {
				~screen.level_((hi_level+lo_level)/2);
			} {
				~screen.level_(hi_level);
			};
   			~screen.text_(round(/* TODO ~params.get_raw_("output_level") */ 0.5*100, 1)); // TODO: introduce engine specific output level
		};

		var redraw_enc2_widget = {
			~screen.move_(enc2_x, enc2_y);
			~screen.level_(lo_level);
			~screen.text_("BPM");
			~screen.move_(enc2_x, enc2_y+12);
			if (focus == 'enc2') {
				~screen.level_((hi_level+lo_level)/2);
			} {
				~screen.level_(hi_level);
			};
			~screen.text_(~params.get_("tempo"));
		};

		var redraw_enc3_widget = {
			~screen.move_(enc3_x, enc3_y);
			~screen.level_(lo_level);
			~screen.text_("SWING");
			~screen.move_(enc3_x, enc3_y+12);
			if (focus == 'enc3') {
				~screen.level_((hi_level+lo_level)/2);
			} {
				~screen.level_(hi_level);
			};
			~screen.text_(~params.get_("swing_amount").asString ++ "%"); // TODO: % concatenation
		};

		var redraw_key2_widget = {
			~screen.move_(key2_x, key2_y);
			if (key2_held or: (focus == 'key2')) {
				~screen.level_((hi_level+lo_level)/2);
			} {
				if (playing) {
					~screen.level_(lo_level);
				} {
					~screen.level_(hi_level);
				};
			};
			~screen.text_("STOP");
		};

		var redraw_key3_widget = {
			~screen.move_(key3_x, key3_y);
			if (key3_held or: (focus == 'key3')) {
				~screen.level_((hi_level+lo_level)/2);
			} {
				if (playing) {
					~screen.level_(hi_level);
				} {
					~screen.level_(lo_level);
				};
			};
			~screen.text_(get_play_label.value());
		};

		~screen.font_size_(16);
		~screen.clear_();

		redraw_enc1_widget.value();

		if (show_event_indicator) {
			redraw_event_flash_widget.value();
		};

		redraw_enc2_widget.value();
		redraw_enc3_widget.value();
		redraw_key2_widget.value();
		redraw_key3_widget.value();
	};

	var steps_widget_x = 2;
	var steps_widget_y = 4;
	var trig_width = 3;
	var trig_height = 3;
	var trig_margin_x = 2;
	var trig_margin_y = 4;
	var additional_extent_x = 1;
	var additional_extent_y = 1;

	var calculate_trig_position = { |tracknum, stepnum|
		var pos_x = steps_widget_x + ((stepnum-1)*(trig_width + trig_margin_x));
		var pos_y = steps_widget_y + ((tracknum-1)*(trig_height + trig_margin_y));
		pos_x@pos_y;
	};

	var redraw_pattern_ui = {
		var patternno = ~params.get_("pattern");
		var redraw_trig = { |stepnum, tracknum|
			var trig_pos = calculate_trig_position.value(tracknum, stepnum);
			var is_set = trig_is_set.value(patternno, stepnum, tracknum);
			var is_played = playpos == stepnum;
			var trig_id = construct_trig_symbol.value(tracknum, stepnum);

			if ( (focus == trig_id) and: (active == trig_id).not ) {
				case
				{is_set} {
					~screen.level_(lo_level);
				}
				{is_played} {
					~screen.level_(lo_level);
				}
				{true} {
					~screen.level_(hi_level);
				};
				~screen.rect_(trig_pos.x-additional_extent_x, trig_pos.y-additional_extent_y, trig_width+(additional_extent_x*2), trig_height+(additional_extent_y*2));
				~screen.fill_();
			};

			case
			{ active == construct_trig_symbol.value(tracknum, stepnum) } {
				~screen.level_(hi_level);
			} { true } {
				case
				{is_set} {
					~screen.level_(hi_level);
				}
				{is_played} {
					~screen.level_((hi_level + lo_level)/2);
				}
				{true} {
					~screen.level_(lo_level);
				};
			};
			~screen.rect_(trig_pos.x, trig_pos.y, trig_width, trig_height);
			~screen.fill_();
		};

		var redraw_samplename = { |tracknum|
			var path = ~params.get_(tracknum.asString ++ "_sample");
			var rightmost_trig_pos = calculate_trig_position.value(tracknum, steps_per_pattern);

			~screen.move_(rightmost_trig_pos.x + trig_width + (trig_margin_x * 2), rightmost_trig_pos.y + (trig_height * 1.25));
			~screen.font_size_(8);
			~screen.level_(hi_level);
			~screen.text_(PathName(path).fileName);
		};

		~screen.clear_();

		// redraw_playpos.value; // TODO: align with grid
	
		(1..num_tracks).do { |tracknum|
			redraw_samplename.value(tracknum);

			(1..steps_per_pattern).do { |stepnum|
				redraw_trig.value(stepnum, tracknum);
			};
		};

		if (show_event_indicator) {
			redraw_event_flash_widget.value();
		};
	};

	var redraw_params_ui = {
		var redraw_row_label = { |label, y_pos, level|
			~screen.level_(level);
			~screen.move_(1, y_pos);
			~screen.text_(label.asString);
		};

		var redraw_row_value = { |value, y_pos, level|
			~screen.level_(level);
			~screen.move_(128, y_pos);
			~screen.text_right_(value.asString);
		};

		var redraw_param = { |param, y_pos, level|
			case
			{ param[\type] == 'separator' } {
				redraw_row_label.value(Array.fill(35) { "_" }.join, y_pos, level);
			}
			{ ['file', 'control', 'option', 'number'].includes(param[\type]) } {
				redraw_row_label.value(param[\name], y_pos, level);
				redraw_row_value.value(param.string_(), y_pos, level);
			};
		};

		var params_ui_cursor_unstepped = (params_ui_cursor/params_ui_cursor_step).round;

		~screen.clear_();

		((params_ui_cursor_unstepped-2)..(params_ui_cursor_unstepped+3)).do { |index, count|
			case
			{index == -1} {
				redraw_row_label.value("PARAMETERS", 1 + 10, lo_level);
			}
			{index == 0} {
			}
			{true} {
				var param = ~params[\params][index-1];
				var level;
				if (index == params_ui_cursor_unstepped) {
					level = hi_level;
				} {
					level = lo_level;
				};
				redraw_param.value(param, 1 + ((count+1) * 10), level);
			}
		};
	};

	var cycle_mode = {
		case
		{ mode == 'main' } {
			mode = 'pattern';
		}
		{ mode == 'pattern' } {
			mode = 'params';
		}
		{ mode == 'params' } {
			mode = 'main';
		};
		focus = nil;
	};

	~engine.name = 'Ack';

	~init = {
		init_trigs.value();
		init_params.value();
		init_sequencer_metro.value();
		load_patterns.value();
		init_ui.value();
		playing = true;
		sequencer_metro.start_();

		~params.set__("last_row_cuts", 2); // TODO: this is the default in sc, not in lua

		~params.read_();
		~params.bang_();
	};

	~cleanup = {
		~params.write_();
		save_patterns.value();
/*
	TODO
		if (grid_device.device_.notNil) {
			grid_device.all_(0);
			grid_device.refresh_();
		};
*/
	};

	~redraw = {
		case
		{ mode == 'main' } {
			redraw_main_ui.value();
		}
		{ mode == 'pattern' } {
			redraw_pattern_ui.value();
		}
		{ mode == 'params' } {
			redraw_params_ui.value();
		};
		~screen.update_(); // norns global
	};

	~enc = { |n, delta|
		case
		{n == 1} {
			// TODO ~params.delta_("output_level", delta); // TODO: introduce engine specific output level
			ui_dirty = true;
		}
		{n == 2} {
			~params.delta_("tempo", delta);
		}
		{n == 3} {
			~params.delta_("swing_amount", delta);
		};
	};

	~key = { |n, s|
		case
		{ mode == 'main' } {
			case
			{n == 1} {
				key1_held = (s == 1);

				if (s == 1) {
					cycle_mode.value();
				};
			}
			{(n == 2) and: (s == 1)} {
				key2_held = true;
				if (playing == false) {
					playpos = 0;
					queued_playpos = 1;
				} {
					playing = false;
					sequencer_metro.stop_();
				}
			}
			{(n == 2) and: (s == 0)} {
				key2_held = false;
			}
			{(n == 3) and: (s == 1)} {
				key3_held = true;
				playing = true;
				sequencer_metro.start_();
			}
			{(n == 3) and: (s == 0)} {
				key3_held = false;
			};
		}
		{ mode == 'pattern' } {
			case
			{n == 1} {
				key1_held = (s == 1);

				if (s == 1) {
					cycle_mode.value();
				};
			}
		}
		{ mode == 'params' } {
			case
			{(n == 1) and: (s == 1)} {
				cycle_mode.value();
			}
			{(n == 2) and: (s == 1)} {
				params_ui_cursor = (params_ui_cursor - params_ui_cursor_step) max: params_ui_cursor_step;
			}
			{(n == 3) and: (s == 1)} {
				params_ui_cursor = (params_ui_cursor + params_ui_cursor_step) min: (~params[\params].size * params_ui_cursor_step);
			};
		};
		ui_dirty = true;
	};

	~mouse = { |what ... args| // TODO: get away from using varargs for ~mouse
		case
		{ what == "leave" } {
			mouse_leave.value();
		}
		{ what == "over" } {
			var x = args[0], y = args[1];
			mouse_over.value(x, y);
		}
		{ what == "down" } {
			var x = args[0], y = args[1], buttonnum = args[2];
			mouse_down.value(x, y, buttonnum);
		}
		{ what == "drag" } {
			var x = args[0], y = args[1], drag = args[2];
			mouse_drag.value(x, y, drag);
		}
		{ what == "move" } {
			var x = args[0], y = args[1];
			mouse_move.value(x, y);
		}
		{ what == "up" } {
			var x = args[0], y = args[1];
			mouse_up.value(x, y);
		}
		{ what == "wheel" } {
			var x_delta = args[0], y_delta = args[1];
			mouse_wheel.value(x_delta, y_delta);
		}
	};
};
)
