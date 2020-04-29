(
var r_path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ ".." +/+ ".." +/+ "r.scd").standardizePath;
var r_api = this.executeFile(r_path);

var init = r_api[\init];
var free = r_api[\free];
var newCommand = r_api[\newCommand];
var connectCommand = r_api[\connectCommand];
var disconnectCommand = r_api[\disconnectCommand];
var deleteCommand = r_api[\deleteCommand];
var setCommand = r_api[\setCommand];
var bulksetCommand = r_api[\bulksetCommand];
var newmacroCommand = r_api[\newmacroCommand];
var deletemacroCommand = r_api[\deletemacroCommand];
var macrosetCommand = r_api[\macrosetCommand];
var readsampleCommand = r_api[\readsampleCommand];
var tapoutputCommand = r_api[\tapoutputCommand];
var tapclearCommand = r_api[\tapclearCommand];
var getSpecs = r_api[\getSpecs];

// server booted assumed
var load_engine = {
	var r_instance;
	var engine;

	r_instance = init.value(
		(
			autostartServer: false,
			trace: true
		)
	);

	engine = ();
	engine.new_ = { |self, name, kind|
		newCommand.value(r_instance, name, kind);
	};
	engine.connect_ = { |self, moduleOutputRef, moduleInputRef|
		connectCommand.value(r_instance, moduleOutputRef, moduleInputRef);
	};
	engine.disconnect_ = { |self, moduleOutputRef, moduleInputRef|
		disconnectCommand.value(r_instance, moduleOutputRef, moduleInputRef);
	};
	engine.delete_ = { |self, moduleRef|
		deleteCommand.value(r_instance, moduleRef);
	};
	engine.set_ = { |self, moduleParameterRef, value|
		setCommand.value(r_instance, moduleParameterRef, value);
	};
	engine.bulkset_ = { |self, bundle|
		bulksetCommand.value(r_instance, bundle);
	};
	engine.newmacro_ = { |self, name, bundle|
		newmacroCommand.value(r_instance, name, bundle);
	};
	engine.deletemacro_ = { |self, name|
		deletemacroCommand.value(r_instance, name);
	};
	engine.macroset_ = { |self, name, value|
		macrosetCommand.value(r_instance, name, value);
	};

	(
		instance: r_instance,
		engine: engine,
		library: (
			specs_: getSpecs.value(r_instance)
		)
	)
};

var free_engine = { |instance|
	free.value(instance[\r_instance]);
};

var module = IdentityDictionary[
	\load_engine -> load_engine,
	\free_engine -> free_engine
];

module
)
