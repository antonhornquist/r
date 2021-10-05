(
var percentage_raw = { |value|
	round(value*100, 1).asString ++ "%"
};

var percentage = { |param|
	percentage_raw.value(param.get_());
};

var adaptive_time_raw = { |ms|
	case
	{ round(ms, 1) < 1000 } {
		round(ms, 1).asString ++ "ms"
	}
	{ round(ms, 1) < 10000 } {
		round(ms/1000, 0.01).asString ++ "s"
	}
	{ true } {
		round(ms/1000, 0.1).asString ++ "s"
	};
};

var adaptive_time = { |param|
	adaptive_time_raw.value(param.get_());
};

var range_raw = { |range|
	case 
	{ range < 0 } {
		range.asString
	}
	{ range > 0 } {
		"+"++range
	}
	{ true } {
		"0"
	}
};

var range = { |param|
	range_raw.value(param.get_());
};

var adaptive_freq_raw = { |hz|
	case
	{ hz <= -1000 } {
		round(hz/1000, 0.1).asString++"kHz";
	}
	{ hz <= -100 } {
		round(hz, 1).asString++"Hz";
	}
	{ hz <= -10 } {
		round(hz, 0.1).asString++"Hz";
	}
	{ hz <= -1 } {
		round(hz, 0.01).asString++"Hz";
	}
	{ hz < 0 } {
		var str = round(hz, 0.001).asString;
		"-"++str[2..str.size-1]++"Hz";
	}
	{ hz < 1 } {
		var str = round(hz, 0.001).asString;
		str[1..str.size-1]++"Hz";
	}
	{ hz < 10 } {
		round(hz, 0.01).asString++"Hz";
	}
	{ hz < 100 } {
		round(hz, 0.1).asString++"Hz";
	}
	{ hz < 1000 } {
		round(hz, 1).asString++"Hz";
	}
	{ hz < 10000 } {
		round(hz/1000, 0.1).asString++"kHz";
	}
	{ true } {
		round(hz/1000, 1).asString ++ "kHz";
	};
};

var adaptive_freq = { |param|
	adaptive_freq_raw.value(param.get_());
};

var adaptive_db_raw = { |db|
	case
	{ db < -10 } {
		round(db, 1).asString++"dB";
	}
	{ db < 0 } {
		round(db, 0.1).asString++"dB";
	}
	{ db < 1 } {
		var str = round(db, 0.001).asString;
		str[2..str.size-1]++"dB";
	}
	{ db < 10 } {
		round(db, 0.01).asString++"dB";
	}
	{ db < 100 } {
		round(db, 0.1).asString++"dB";
	}
	{ true } {
		round(db/1000, 1).asString ++ "dB";
	};
};

var adaptive_db = { |param|
	adaptive_db_raw.value(param.get_());
};

var format = { |param, value, units|
	value.asString ++ " " ++ (units ? param[\controlspec].units ? "")
};

var round = { |precision|
	{ |param|
		format.value(param, round(param.get_, precision));
	}
};

var module = (
	percentage: percentage,
	adaptive_time: adaptive_time,
	range: range,
	adaptive_freq: adaptive_freq,
	adaptive_db: adaptive_db,
	round_: { |self, precision|
		round.value(precision);
	}
);

module
)
