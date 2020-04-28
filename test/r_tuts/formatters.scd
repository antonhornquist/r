(

var format = { |param, value, units|
	value.asString ++ " " ++ (units ? param[\controlspec].units ? "")
};

/*
var format_freq_raw = { |freq|
	case
	{ freq < 0.1 } {
		round(freq, 0.001) ++ " Hz"
	}
	{ freq < 100 } {
		round(freq, 0.01) ++ " Hz"
	}
	{ round(freq, 1) < 1000 } {
		round(freq, 1) ++ " Hz"
	}
	{ true } {
		round(freq / 1000, 0.01) ++ " kHz"
	}
};
*/

var percentage = { |param|
	format.value(param, round(param.get__*100), "%");
};

var round = { |precision|
	{ |param|
		format.value(param, round(param.get__, precision));
	}
};

/*
var format_freq = { |param|
	format_freq_raw.value(param.get__);
};
*/

var module = (
	percentage: percentage,
	round__: { |self, precision|
		round.value(precision);
	}
);

module
)
