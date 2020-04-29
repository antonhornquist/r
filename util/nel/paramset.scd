(
var init_paramset = {
	var params = [];

/*
	var paramset = IdentityDictionary[
		\add -> { |param|
			var type = param[\type].asSymbol;
			var id = param[\id].asSymbol;
			var name = param[\name];
			var controlspec = param[\controlspec].asSpec;
			var action = param[\action];
			var formatter = param[\formatter];

			if (type != 'control') {
				Error("only params of type 'control' are supported").throw;
			};

			params = params.add(
				IdentityDictionary[
					\type -> type,
					\id -> id,
					\name -> name,
					\controlspec -> controlspec,
					\action -> action,
					\formatter -> formatter,
					\raw -> if (controlspec.default.notNil) { controlspec.unmap(controlspec.default) } { 0 },
					\get__ -> { |self| // TODO
						self[\controlspec].map(self[\raw])
					}
//					\set__ -> { |self, value| // TODO
//						self[\raw] = self[\controlspec].unmap(round(value, self[\controlspec].step));
//					}
				]
			);

		},
		\lookup_param -> { |id|
			params.detect { |param| param[\id] == id.asSymbol };
		},
		\get_name -> { |id, value|
			var param = self.lookup_param_(id);
			param[\name];
		},
		\set -> { |id, value|
			var param = self.lookup_param_(id);
			param[\raw] = param[\controlspec].unmap(value);
		},
		\get -> { |id|
			var param = self.lookup_param_(id);
			param[\controlspec].map(param[\raw]);
		},
		\set_raw -> { |id, value|
			var param = self.lookup_param_(id);
			param[\raw] = value.clip(0, 1);
			param[\action].value(param[\controlspec].map(param[\raw]));
		},
		\get_raw -> { |id|
			var param = self.lookup_param_(id);
			param[\raw];
		},
		\delta -> { |id, d|
			var param = self.lookup_param_(id);
			paramset[\set_raw].value(id, param[\raw] + (d/100));
		},
		\bang -> {
			params.do { |param|
				var value = paramset[\get].value(param[\id]);
				param[\action].value(value);
			};
		},
		\write -> {
			Error("not implemented yet").throw;
		},
		\read -> {
			Error("not implemented yet").throw;
		},
		\string -> { |id|
			var param = self.lookup_param_(id);
			if (param[\formatter].notNil) {
				param[\formatter].value(param);
			} {
				var a = round(paramset[\get].value(param[\id]), 0.01);
				a.asString + param[\controlspec].units;
			};
		}
	];
*/
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

/*
		params = params.add(
			IdentityDictionary[
				\type -> type,
				\id -> id,
				\name -> name,
				\controlspec -> controlspec,
				\action -> action,
				\formatter -> formatter,
				\raw -> if (controlspec.default.notNil) { controlspec.unmap(controlspec.default) } { 0 },
				\get__ -> { |self| // TODO
					self[\controlspec].map(self[\raw])
				}
//					\set__ -> { |self, value| // TODO
//						self[\raw] = self[\controlspec].unmap(round(value, self[\controlspec].step));
//					}
			]
		);
*/

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
	paramset.get_name_ = { |self, id, value|
		var param = self.lookup_param_(id);
		param[\name];
	};
	paramset.set_ = { |self, id, value|
		var param = self.lookup_param_(id);
		param[\raw] = param[\controlspec].unmap(value);
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
