(
var init_paramset = {
	var params = [];

	var paramset = ();
	paramset.add_ = { |self, arg_param|
		var type = arg_param[\type].asSymbol;
		var id = arg_param[\id].asSymbol;
		var name = arg_param[\name];
		var controlspec = arg_param[\controlspec].asSpec;
		var action = arg_param[\action];
		var formatter = arg_param[\formatter];
		var param;

		if (type != 'control') {
			Error("only params of type 'control' are supported").throw;
		};

		param = ();
		param[\type] = type;
		param[\id] = id;
		param[\name] = name;
		param[\controlspec] = controlspec;
		param[\action] = action;
		param[\formatter] = formatter;
		param[\raw] = if (controlspec.default.notNil) { controlspec.unmap(controlspec.default) } { 0 };
		param.get_ = { |self| // TODO
			self[\controlspec].map(self[\raw])
		};

		params = params.add(param);
	};
	paramset.lookup_param_ = { |self, id|
		params.detect { |param| param[\id] == id.asSymbol };
	};
	paramset.get_name_ = { |self, id|
		var param = self.lookup_param_(id);
		param[\name];
	};
	paramset.set_ = { |self, id, value|
		var param = self.lookup_param_(id);
		param[\raw] = param[\controlspec].unmap(value);
		paramset.set_raw_(id, param[\controlspec].unmap(value));
	};
	paramset.get_ = { |self, id|
		var param = self.lookup_param_(id);
		param[\controlspec].map(param[\raw]);
	};
	paramset.set_raw_ = { |self, id, value|
		var param = self.lookup_param_(id);
		param[\raw] = value.clip(0, 1);
		param[\action].value(param[\controlspec].map(param[\raw]));
	};
	paramset.get_raw_ = { |self, id|
		var param = self.lookup_param_(id);
		param[\raw];
	};
	paramset.delta_ = { |self, id, d|
		var param = self.lookup_param_(id);
		paramset.set_raw_(id, param[\raw] + (d/100));
	};
	paramset.bang_ = { |self|
		params.do { |param|
			var value = paramset.get_(param[\id]);
			param[\action].value(value);
		};
	};
	paramset.write = { |self|
		Error("not implemented yet").throw;
	};
	paramset.read_ = { |self|
		Error("not implemented yet").throw;
	};
	paramset.string_ = { |self, id|
		var param = self.lookup_param_(id);
		if (param[\formatter].notNil) {
			param[\formatter].value(param);
		} {
			var a = round(paramset.get_(param[\id]), 0.01);
			a.asString + param[\controlspec].units;
		};
	};

	paramset;
};

var module = IdentityDictionary[
	\init_paramset -> init_paramset
];

module;
)
