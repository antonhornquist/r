(
// utility library for rendering raw parameter values (0 .. 1.0) onto a ring

var run_tests = {
	run_render_ring_tests.value();
	run_spawn_render_ring_function_tests.value();
	postln("tests ok");
};

var run_render_ring_tests = {
	assert_array_equal.value(
		render_ring.value(0, nil, nil, 8, 5),
		[0, 0, 0, 5, 5, 5, 15, 0]
	);

	assert_array_equal.value(
		render_ring.value(0.25, nil, nil, 8, 5),
		[0, 0, 0, 5, 5, 5, 0, 15]
	);

	assert_array_equal.value(
		render_ring.value(0.5, nil, nil, 8, 5),
		[15, 0, 0, 5, 5, 5, 0, 0]
	);

	assert_array_equal.value(
		render_ring.value(0.75, nil, nil, 8, 5),
		[0, 15, 0, 5, 5, 5, 0, 0]
	);

	assert_array_equal.value(
		render_ring.value(1, nil, nil, 8, 5),
		[0, 0, 15, 5, 5, 5, 0, 0]
	);

	assert_array_equal.value(
		render_ring.value(0, [ 0.5 ], nil, 8, 5),
		[0, 0, 0, 5, 5, 5, 15, 0]
	);

	assert_array_equal.value(
		render_ring.value(0, [ 0.5, 0.75 ], nil, 8, 5),
		[2, 2, 0, 5, 5, 5, 15, 0]
	);

	assert_array_equal.value(
		render_ring.value(0, [ 0.5, 0.75, 1 ], nil, 8, 5),
		[1, 2, 2, 5, 5, 5, 15, 0]
	);

	assert_array_equal.value(
		render_ring.value(0, nil, 0, 8, 5),
		[0, 0, 0, 5, 5, 5, 15, 0]
	);

	assert_array_equal.value(
		render_ring.value(0, nil, 2, 8, 5),
		[15, 0, 0, 0, 0, 5, 5, 5]
	);

	assert_array_equal.value(
		render_ring.value(0, nil, 4, 8, 5),
		[5, 5, 15, 0, 0, 0, 0, 5]
	);

	assert_array_equal.value(
		render_ring.value(0, nil, 6, 8, 5),
		[0, 5, 5, 5, 15, 0, 0, 0]
	);
};

var run_spawn_render_ring_function_tests = {
	var spawned_render_ring_function = spawn_render_ring_function.value(8, 5);

	assert_array_equal.value(
		spawned_render_ring_function.value(0),
		[0, 0, 0, 5, 5, 5, 15, 0]
	);

	assert_array_equal.value(
		spawned_render_ring_function.value(0.25),
		[0, 0, 0, 5, 5, 5, 0, 15]
	);

	assert_array_equal.value(
		spawned_render_ring_function.value(0.5),
		[15, 0, 0, 5, 5, 5, 0, 0]
	);

	assert_array_equal.value(
		spawned_render_ring_function.value(0.75),
		[0, 15, 0, 5, 5, 5, 0, 0]
	);

	assert_array_equal.value(
		spawned_render_ring_function.value(1),
		[0, 0, 15, 5, 5, 5, 0, 0]
	);

	assert_array_equal.value(
		spawned_render_ring_function.value(0, [ 0.5 ]),
		[0, 0, 0, 5, 5, 5, 15, 0]
	);

	assert_array_equal.value(
		spawned_render_ring_function.value(0, [ 0.5, 0.75 ]),
		[2, 2, 0, 5, 5, 5, 15, 0]
	);

	assert_array_equal.value(
		spawned_render_ring_function.value(0, [ 0.5, 0.75, 1 ]),
		[1, 2, 2, 5, 5, 5, 15, 0]
	);

	spawned_render_ring_function = spawn_render_ring_function.value(8, 5, 0);

	assert_array_equal.value(
		spawned_render_ring_function.value(0),
		[0, 0, 0, 5, 5, 5, 15, 0]
	);

	spawned_render_ring_function = spawn_render_ring_function.value(8, 5, 2);

	assert_array_equal.value(
		spawned_render_ring_function.value(0),
		[15, 0, 0, 0, 0, 5, 5, 5]
	);

	spawned_render_ring_function = spawn_render_ring_function.value(8, 5, 4);

	assert_array_equal.value(
		spawned_render_ring_function.value(0),
		[5, 5, 15, 0, 0, 0, 0, 5]
	);

	spawned_render_ring_function = spawn_render_ring_function.value(8, 5, 6);

	assert_array_equal.value(
		spawned_render_ring_function.value(0),
		[0, 5, 5, 5, 15, 0, 0, 0]
	);
};

var assert_array_equal =
{ |a, b|
	if (a != b) {
		Error("assertion failed, expected a == b, actual % != %".format(a, b)).throw;
	};
};

var spawn_render_ring_function = { |num_ring_leds, num_ring_led_range, top_led|
	var render_ring_function = { |value, previous_values|
		var led_levels = Array.fill(num_ring_leds);
		render_base.value(led_levels, 5);
		render_range.value(led_levels, value, previous_values);
		led_levels;
	};

	var render_range = { |led_levels, value, previous_values|
		var top_led_index = ((num_ring_led_range-1)/2);
		var num_base_leds = (num_ring_leds - num_ring_led_range);

		var range_led_levels = Array.fill(num_ring_led_range, 0);

		var render_previous_values = { |previous_values, max_level|
			var num_previous_values = previous_values.size;
			var prev_led_n, led_n, max_led_n, min_led_n, level;
			if (num_previous_values > 1) {
				prev_led_n = translate.value(previous_values[0]);
				(num_previous_values-1).do { |idx|
					var offset_idx = idx+1;
					led_n = translate.value(previous_values[offset_idx]);
					max_led_n = max(prev_led_n, led_n);
					min_led_n = min(prev_led_n, led_n);

					level = max((max_level/(num_previous_values-1)*offset_idx).round, 1).asInteger;

					render_value_range.value(min_led_n, max_led_n, level);

					prev_led_n = led_n;
				};
			};
		};

		var render_value = { |value, level|
			render_led.value(translate.value(value), level);
		};

		var translate = { |value|
			(value.clip(0, 1)*(num_ring_led_range-1)).round;
		};

		var render_value_range = { |start_n, end_n, level|
			(start_n..end_n).do { |led_n|
				render_led.value(led_n, level);
			}
		};

		var render_led = { |led_index, level|
			range_led_levels[led_index] = level;
		};

		if (previous_values.notNil) {
			render_previous_values.value(previous_values, 2);
		};

		render_value.value(value, 15);

		range_led_levels.do { |level, led_index|
			led_levels[
				(if (led_index < top_led_index) {
					top_led_index + num_base_leds + led_index + 1;
				} {
					led_index - top_led_index;
				} + top_led).mod(num_ring_leds)
			] = level;
		};
	};

	var render_base = { |led_levels, level|
		var num_base_leds = (num_ring_leds - num_ring_led_range);
		var base_start = (num_ring_led_range-1)/2+1;
		num_base_leds.do { |index|
			led_levels[
				((base_start+index) + top_led).mod(num_ring_leds)
			] = level;
		};

	};

	num_ring_leds = num_ring_leds ?? 64;
	num_ring_led_range = num_ring_led_range ?? 45; // should be an odd number
	top_led = top_led ?? 0; // should be an odd number

	render_ring_function;
};

var render_ring = { |value, previous_values, top_led, num_ring_leds, num_ring_led_range|
	var spawned_render_ring = spawn_render_ring_function.value(num_ring_leds, num_ring_led_range, top_led);
	spawned_render_ring.value(value, previous_values);
};

var module = IdentityDictionary[
	\spawn_render_ring_function -> spawn_render_ring_function,
	\render_ring -> render_ring
];

// run_tests.value(); // uncomment to run tests
module
)
