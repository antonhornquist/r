(
~control = (
	new__: { |self, id, name, controlspec, formatter|
		var instance = self.copy;
		instance[\id] = id;
		instance[\name] = name;
		instance[\controlspec] = controlspec.asSpec;
		instance[\formatter] = formatter;
		instance[\raw] = 0;
	},
	set__: { |self, value|
		self[\raw] = self[\controlspec].unmap(value);
	},
	get__: { |self|
		self[\controlspec].map(self[\raw]);
	},
	set_raw__: { |self, value|
		self[\raw] = value;
	},
	get_raw__: { |self|
		self[\raw]
	}
)
)
Event
~param1 = ~control.new__("test", "name", \freq)
~param1.get__()
~param1.set__(440)


// or


(
~control = (
	new__fn: { |self, id, name, controlspec, formatter|
		var instance = self.copy;
		instance[\id] = id;
		instance[\name] = name;
		instance[\controlspec] = controlspec.asSpec;
		instance[\formatter] = formatter;
		instance[\raw] = 0;
	},
	set__fn: { |self, value|
		self[\raw] = self[\controlspec].unmap(value);
	},
	get__fn: { |self|
		self[\controlspec].map(self[\raw]);
	},
	set_raw__fn: { |self, value|
		self[\raw] = value;
	},
	get_raw__fn: { |self|
		self[\raw]
	}
)
)
Event
~param1 = ~control.new__fn("test", "name", \freq)
~param1.get__fn()
~param1.set__fn(440)

(
var module = (
	new: { |self, id, name, controlspec, formatter|
		var instance = self.copy;
		instance[\id] = id;
		instance[\name] = name;
		instance[\controlspec] = controlspec.asSpec;
		instance[\formatter] = formatter;
		instance[\raw] = 0;
	},
	set: { |self, value|
		self[\raw] = self[\controlspec].unmap(value);
	},
	get: { |self|
		self[\controlspec].map(self[\raw]);
	},
	set_raw: { |self, value|
		self[\raw] = value;
	},
	get_raw: { |self|
		self[\raw]
	}
);

var result = ();

module.keysValuesDo.collect { |value, key|
	if (value.class == Function) {
		result[(key.asString++"__").asSymbol] = value;
	} {
		result[key] = value;
	}
};

result;
)