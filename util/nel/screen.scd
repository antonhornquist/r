(
// utility library to mock a UserView as a norns screen, drawable with a limited subset of norns screen functions. uses 1 based coordinates. uses global ~screen global for storage of relevant objects (not functions). relies on global ~redraw function wherein screen_* commands are performed.

var screen_width = 128;
var screen_height = 64;
var default_font_size = 8;

var default_background_color = Color.black;
var default_foreground_color = Color.white;

var default_colors = [0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 1].collect { |level| default_background_color.blend(default_foreground_color, level) };

var screen_init = { |parent_view, x_pos, y_pos, scale, colors|
	var background_color = (colors ? default_colors)[0]; 
	var instance = (
		view: UserView(parent_view, Rect(x_pos, y_pos, round(screen_width*scale), round(screen_height*scale)))
			.background_(background_color)
			.drawFunc_({
				instance[\queued_screen_ops].do { |screen_op|
					screen_op.value;
				};
				instance[\queued_screen_ops] = [];
			})
			.clearOnRefresh_(false),
		font_size: default_font_size,
		font: Font(lookup_font.value, calculate_scaled_font_size.value(scale, default_font_size)),
		position: 1@1,
		scale: scale,
		colors: colors ? default_colors,
		level: 15,
		queued_screen_ops: []
	);
	instance;
};

var screen_level = { |instance, level|
	instance[\level] = level;
};

var screen_rect = { |instance, x_pos, y_pos, width, height|
	var scale = instance[\scale];

	x_pos = x_pos - 1;
	y_pos = y_pos - 1;

	instance[\queued_screen_ops] = instance[\queued_screen_ops].add(
		{
			// TODO [\Pen, \addRect, Rect(round(scale * x_pos), round(scale * y_pos), round(scale * width), round(scale * height))].debug;
			Pen.addRect(Rect(round(scale * x_pos), round(scale * y_pos), round(scale * width), round(scale * height)));
		}
	);
};

var screen_move = { |instance, x_pos, y_pos|
	var scale = instance[\scale];
	instance[\position] = x_pos@y_pos;
	x_pos = x_pos - 1;
	y_pos = y_pos - 1;
	instance[\queued_screen_ops] = instance[\queued_screen_ops].add(
		{
			// TODO [\Pen, \moveTo, round(scale * x_pos)@round(scale * y_pos)].debug;
			Pen.moveTo(round(scale * x_pos)@round(scale * y_pos));
		}
	);
};

var screen_line = { |instance, x_pos, y_pos|
	var scale = instance[\scale];
	var level = instance[\level];
	x_pos = x_pos - 1;
	y_pos = y_pos - 1;
	instance[\queued_screen_ops] = instance[\queued_screen_ops].add(
		{
			// TODO [\Pen, \width_, scale].debug;
			Pen.width = scale;
			// TODO [\Pen, \lineTo, round(scale * x_pos)@round(scale * y_pos)].debug;
			Pen.lineTo(round(scale * x_pos)@round(scale * y_pos));
		}
	);
};

var screen_line_rel = { |instance, x_rel, y_rel|
	var scale = instance[\scale];
	var level = instance[\level];
	var position = instance[\position];
	var x_pos = position.x + x_rel;
	var y_pos = position.y + y_rel;
	instance[\queued_screen_ops] = instance[\queued_screen_ops].add(
		{
			// TODO [\Pen, \width_, scale].debug;
			Pen.width = scale;
			// TODO [\Pen, \lineTo, round(scale * x_pos)@round(scale * y_pos)].debug;
			Pen.lineTo(round(scale * x_pos)@round(scale * y_pos));
		}
	);
};

var screen_stroke = { |instance|
	var level = instance[\level];
	var color = instance[\colors][level];
	instance[\queued_screen_ops] = instance[\queued_screen_ops].add(
		{
			// TODO [\Pen, \strokeColor_, color].debug;
			Pen.strokeColor = color;
			// TODO [\Pen, \stroke].debug;
			Pen.stroke;
		}
	);
};

var screen_text = { |instance, text|
	var scale = instance[\scale];
	var position = instance[\position];
	var level = instance[\level];
	var color = instance[\colors][level];

	var x_pos = position.x - 1;
	var y_pos = position.y - 1;

	y_pos = y_pos - (instance[\font_size] * 0.8);

	text = text.asString;

	instance[\queued_screen_ops] = instance[\queued_screen_ops].add(
		{
			// TODO [\Pen, \font_, instance[\font]].debug;
			Pen.font = instance[\font];
			// TODO [\Pen, \color_, color].debug;
			Pen.color = color;
			// TODO [\Pen, \stringAtPoint, text, round(scale * x_pos)@round(scale * y_pos)].debug;
			Pen.stringAtPoint(text, round(scale * x_pos)@round(scale * y_pos));
		}
	);
};

var screen_font_size = { |instance, font_size|
	var scale = instance[\scale];
	instance[\font_size] = font_size;
	instance[\font].size = calculate_scaled_font_size.value(scale, font_size);
};

var screen_text_extents = { |instance, text|
	var scale = instance[\scale];
	var font = instance[\font];
	(text.bounds(font).width)/scale;
};

var screen_fill = { |instance|
	var level = instance[\level];
	var color = instance[\colors][level];
	instance[\queued_screen_ops] = instance[\queued_screen_ops].add(
		{
			// TODO [\Pen, \fillColor_, color].debug;
			Pen.fillColor = color;
			// TODO [\Pen, \fill].debug;
			Pen.fill;
		}
	);
};

var screen_clear = { |instance|
	var scale = instance[\scale];
	var view = instance[\view];
	var background_color = instance[\colors][0];
	instance[\queued_screen_ops] = instance[\queued_screen_ops].add(
		{
			var width = view.bounds.width;
			var height = view.bounds.height;
			var x_pos = 0;
			var y_pos = 0;
			// TODO [\Pen, \addRect, Rect(round(scale * x_pos), round(scale * y_pos), round(scale * width), round(scale * height))].debug;
			Pen.addRect(Rect(round(scale * x_pos), round(scale * y_pos), round(scale * width), round(scale * height)));
			// TODO [\Pen, \fillColor_, background_color].debug;
			Pen.fillColor = background_color;
			// TODO [\Pen, \fill].debug;
			Pen.fill;
		}
	);
};

var screen_update = { |instance|
	defer {
		instance[\view].refresh;
	}
};

var calculate_scaled_font_size = { |scale, unscaled_font_size|
	round(unscaled_font_size * scale * 13 / 16) // TODO: ideal font size
};

var lookup_font = {
	Font.defaultSansFace
};

var module = IdentityDictionary[
	\screen_init -> screen_init,
	\screen_rect -> screen_rect,
	\screen_move -> screen_move,
	\screen_line -> screen_line,
	\screen_stroke -> screen_stroke,
	\screen_fill -> screen_fill,
	\screen_level -> screen_level,
	\screen_text -> screen_text,
	\screen_text_extents -> screen_text_extents,
	\screen_font_size -> screen_font_size,
	\screen_clear -> screen_clear,
	\screen_update -> screen_update
];

module
)
