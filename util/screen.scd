(
// utility library to mock a UserView as a norns screen, drawable with a limited subset of norns screen functions. uses 1 based coordinates. uses global ~screen global for storage of relevant objects (not functions). relies on global ~redraw function wherein screen_* commands are performed.

var width = 128;
var height = 64;
var default_font_size = 8;

var global_screen_init = { |parent_view, x, y, scale|
/*
	TODO
	if (~screen.notNil) {
		Error("~screen global already initialized").throw;
	};
*/
	var instance = screen_init.value(parent_view, x, y, scale, {
		~screen[\redraw] = false;
		~redraw.value;
		if (~screen[\redraw]) {
			defer { instance[\view].refresh };
		};
	});

	~screen = instance;

	~screen_rect = { |x, y, width, height|
		screen_rect.value(instance, x, y, width, height);
	};

	~screen_move = { |x, y|
		screen_move.value(instance, x, y);
	};

	~screen_line = { |x, y|
		screen_line.value(instance, x, y);
	};

	~screen_stroke = {
		screen_stroke.value(instance);
	};

	~screen_fill = {
		screen_fill.value(instance);
	};

	~screen_level = { |level|
		screen_level.value(instance, level);
	};

	~screen_text = { |text|
		screen_text.value(instance, text);
	};

	~screen_text_extents = { |text|
		screen_text_extents.value(instance, text);
	};

	~screen_font_size = { |size|
		screen_font_size.value(instance, size);
	};

	~screen_clear = {
		screen_clear.value(instance);
	};

	~screen_update = {
		screen_update.value(instance);
	};
};

/*
	TODO: when triggered?
var global_screen_free = {
	if (~screen.isNil) {
		Error("~screen global already freed").throw;
	} {
		~screen = nil;
	};
};
*/

var screen_init = { |parent_view, x, y, scale, draw_func|
	var view = UserView(parent_view, Rect(x, y, round(width*scale), round(height*scale)))
		.background_(Color.black)
		.drawFunc_(draw_func)
/*
	TODO
		.keyDownAction_({ |view, char, mod, unicode, keycode, key|
			key_is_pressed.value(gui_state, char);
		})
		.keyUpAction_({ |view, char, mod, unicode, keycode, key|
			key_is_released.value(gui_state, char);
		})
*/
		.clearOnRefresh_(false)
		//.animate_(true)
		//.frameRate_(35)
	;

	(
		view: view,
		font_size: default_font_size,
		font: Font(lookup_font.value, calculate_scaled_font_size.value(scale, default_font_size)),
		position: 1@1,
		scale: scale,
		level: 15
	);
};

var screen_level = { |instance, level|
	instance[\level] = level;
	instance[\color] = Color.new(level/15, level/15, level/15);
};

var screen_rect = { |instance, x, y, width, height|
	var scale = instance[\scale];

	x = x - 1;
	y = y - 1;

	Pen.addRect(Rect(round(scale * x), round(scale * y), round(scale * width), round(scale * height)));
};

var screen_move = { |instance, x, y|
	var scale = instance[\scale];
	instance[\position] = x@y;
	x = x - 1;
	y = y - 1;
	Pen.moveTo(round(scale * x)@round(scale * y));
};

var screen_line = { |instance, x, y|
	var scale = instance[\scale];
	var color = instance[\color];
	x = x - 1;
	y = y - 1;
	Pen.width = scale;
	Pen.lineTo(round(scale * x)@round(scale * y));
};

var screen_stroke = { |instance|
	var color = instance[\color];
	Pen.strokeColor = color;
	Pen.stroke;
};

var screen_text = { |instance, text|
	var scale = instance[\scale];
	var position = instance[\position];
	var color = instance[\color];

	x = position.x - 1;
	y = position.y - 1;

	//y = y - (instance[\font].size * 0.8); // TODO: used to be y - (font_size * 13 / 16)
	y = y - (instance[\font_size] * 0.8); // TODO: used to be y - (font_size * 13 / 16)

	text = text.asString;

	Pen.font = instance[\font];
	Pen.fillColor = color; // TODO: is this string color?
	Pen.stringAtPoint(text, round(scale * x)@round(scale * y));
};

var screen_font_size = { |instance, font_size|
	var scale = instance[\scale];
	instance[\font_size] = font_size;
	instance[\font].size = calculate_scaled_font_size.value(scale, font_size);
};

var screen_text_extents = { |instance, text|
	var scale = instance[\scale];
	var font = instance[\font];
	Pen.font = font;
	(text.bounds(font).width)/scale;
};

var screen_fill = { |instance|
	Pen.fillColor = instance[\color];
	Pen.fill;
};

var screen_clear = { |instance|
	instance[\view].clearDrawing;
};

var screen_update = { |instance|
	instance[\redraw] = true;
};

var calculate_scaled_font_size = { |scale, unscaled_font_size|
	round(unscaled_font_size * scale * 13 / 16) // TODO: ideal font size
};

var lookup_font = {
	Font.availableFonts.detect { |name| "Akkurat-Mono" == name }
	?
	Font.defaultSansFace
	?
	Font.availableFonts.detect { |name| "Consolas" == name }
	?
	Font.defaultMonoFace;
};

var module = IdentityDictionary[
	\global_screen_init -> global_screen_init,
	//\global_screen_free -> global_screen_free
/*
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
	\screen_clear -> screen_clear
	\screen_update -> screen_update
*/
];

module
)
