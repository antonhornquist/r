(
var include_relative = { |relative_path|
	var path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ relative_path).standardizePath;
	if (File.exists(path)) {
		this.executeFile(path);
	} {
		Error("include_relative: file % does not exist".format(path.quote)).throw;
	};
};

var r = include_relative.value(".." +/+ ".." +/+ ".." +/+ "r.scd");
var getCoreStdModuleSpecs = r[\getCoreStdModuleSpecs];

var specs = getCoreStdModuleSpecs.value;

var util = (
	// utility function to expand a moduleparam ref to #polyphony ones suffixed with 1..polyphony
	poly_expand_: { |self, moduleparam, polyphony|
		var module, param;
		# module, param = util.split_ref_(moduleparam);

		polyphony.collect { |i|
			var voicenum = i + 1;
			util.param_voice_ref_(module, param, voicenum);
		}.join(" ");
	},
	param_voice_ref_: { |self, module, param, voicenum|
		module ++ voicenum ++ "." ++ param
	},
	split_ref_: { |self, ref|
		ref = ref.asString;

		case
		{ref.includes($/)} {
			ref.split($/);
		}
		{ref.includes($*)} {
			ref.split($*);
		}
		{ref.includes($.)} {
			ref.split($.);
		}
	}
);

var engine = (
	// utility function to create multiple modules suffixed 1..polyphony
	poly_new_: { |self, name, kind, polyphony|
		kind = kind.asSymbol;
		if (specs[kind].notNil) {
			polyphony.do { |i|
				var voicenum = i + 1;
				~engine.new_(name++voicenum, kind); // TODO
			};
		} {
			Error(kind.asString ++ " not a valid module type").throw;
		};
	},
	// utility function to set param of multiple modules suffixed 1..polyphony
	poly_set_: { |self, ref, value, polyphony|
		var module, param;
		# module, param = util.split_ref_(ref);
		polyphony.do { |i|
			var voicenum = i + 1;
			~engine.set_(util.param_voice_ref_(module, param, voicenum), value); // TODO
		};
	},
	// utility function to connect modules suffixed with 1..polyphony
	poly_connect_: { |self, output, input, polyphony|
		var sourcemodule, outputref;
		var destmodule, inputref;
		# sourcemodule, outputref = util.split_ref_(output);
		# destmodule, inputref = util.split_ref_(input);
		polyphony.do { |i|
			var voicenum = i + 1;
			~engine.connect_(sourcemodule++voicenum++"/"++outputref, destmodule++voicenum++"*"++inputref); // TODO
		};
	},
);

var module = IdentityDictionary[
	\specs -> specs,
	\metadata -> 'TODO',
	\util -> util,
	\engine -> engine
];

module;
)
