(
var init_paramset = {
	var params = [];

	var paramset = IdentityDictionary[
		\add -> { |param|
			var type = param[\type];
			var id = param[\id];
			var name = param[\name];
			var controlspec = param[\controlspec];
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
					\formatter -> formatter
				]
			);

		},
		\lookup_param -> { |id|
			params.detect { |param| param[\id] == id };
		},
		\get_name -> { |id, value|
			var param = paramset[\lookup_param].value(id);
			param[\name];
		},
		\set -> { |id, value|
			var param = paramset[\lookup_param].value(id);
			param[\raw] = param[\controlspec].unmap(value);
		},
		\get -> { |id|
			var param = paramset[\lookup_param].value(id);
			param[\controlspec].map(param[\raw]);
		},
		\set_raw -> { |id, value|
			var param = paramset[\lookup_param].value(id);
			param[\raw] = value.clip(0, 1);
			param[\action].value(param[\controlspec].map(param[\raw]));
		},
		\get_raw -> { |id|
			var param = paramset[\lookup_param].value(id);
			param[\raw];
		},
		\delta -> { |id, d|
			var param = paramset[\lookup_param].value(id);
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
			var param = paramset[\lookup_param].value(id);
			if (param[\formatter].notNil) {
				param[\formatter].value(param);
			} {
				var a = round(paramset[\get].value(param[\id]), 0.01);
				a.asString + param[\controlspec].units;
			};
		}
	];

	paramset;
};

var module = IdentityDictionary[
	\init_paramset -> init_paramset
];

module
)
