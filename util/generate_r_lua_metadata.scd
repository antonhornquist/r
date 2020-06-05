(
var r_path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ ".." +/+ "r.scd").standardizePath;
var r = this.executeFile(r_path);
var getCoreStdModuleMetadata = r[\getCoreStdModuleMetadata];

var formatLuaMetadata = { |metadata|
	metadata.collect { |moduledef|
		var module_name = moduledef.key.asString;
		var moduledef_metadata = moduledef.value;
		var parameters = moduledef_metadata[\parameters];
		var inputs = moduledef_metadata[\inputs];
		var outputs = moduledef_metadata[\outputs];
/*
		var visuals = moduledef_metadata[\visuals];
		var sampleSlots = moduledef_metadata[\sampleSlots];
*/

		"metadata['"++module_name++"'] = {\n"++
		[
			parameters !? { formatLuaParameterMetadata.value(parameters) },
			inputs !? { formatLuaInputMetadata.value(inputs) },
			outputs !? { formatLuaOutputMetadata.value(outputs) },
		].reject { |section| section.isNil }.join(",\n") ++ "\n" ++
		"}" ++ "\n";
	}.join($\n);
};

var formatLuaParameterMetadata = { |parameter_metadata|
	"\tparameters = {\n"++
	parameter_metadata.collect { |parameter| // TODO: report error when controlSpec is not found / or rely on .asSpec
		var param_name = parameter.key;
		var param_metadata = parameter.value;
		var param_metadata_spec = param_metadata[\Spec];
		var param_metadata_description = param_metadata[\Description];
			
		"\t\t['" ++ param_name ++ "'] = " ++ "{" ++ "\n" ++
		[
			"\t\t\t" ++ "spec = " ++ if (param_metadata_spec.class == Symbol) {
				"\\" ++ param_metadata_spec.asString
			} {
				param_metadata_spec.asSpecifier !? { |specifier| "ControlSpec."++specifier.asString.toUpper } ? ("ControlSpec.new("++[
					switch (param_metadata_spec.minval) { -inf } { "-math.huge" } { inf } { "math.huge" } ? param_metadata_spec.minval,
					switch (param_metadata_spec.maxval) { -inf } { "-math.huge" } { inf } { "math.huge" } ? param_metadata_spec.maxval,
					param_metadata_spec.warp.asSpecifier.asString.quote,
					param_metadata_spec.step,
					switch (param_metadata_spec.default) { -inf } { "-math.huge" } { inf } { "math.huge" } ? param_metadata_spec.default,
					param_metadata_spec.units.quote
				].join(", ")++")")
			},
			if (param_metadata_description.notNil) {
				"\t\t\t" ++ "description = " ++ param_metadata_description.quote
			}
		].reject { |section| section.isNil }.join(",\n") ++ "\n" ++
		"\t\t" ++ "}"
	}.join(",\n") ++ "\n"
	"\t}"
};

var formatLuaInputMetadata = { |input_metadata|
	"\tinputs = {\n"++
	input_metadata.collect { |input| // TODO: report error when controlSpec is not found / or rely on .asSpec
		var input_name = input.key;
		var input_metadata = input.value;
		var input_metadata_description = input_metadata[\Description];
			
		"\t\t['" ++ input_name ++ "'] = " ++ "{" ++ "\n" ++
		"\t\t\t" ++ "description = " ++ input_metadata_description.quote ++ "\n" ++
		"\t\t" ++ "}"
	}.join(",\n") ++ "\n"
	"\t}"
};

var formatLuaOutputMetadata = { |output_metadata|
	"\toutputs = {\n"++
	output_metadata.collect { |output| // TODO: report error when controlSpec is not found / or rely on .asSpec
		var output_name = output.key;
		var output_metadata = output.value;
		var output_metadata_description = output_metadata[\Description];
			
		"\t\t['" ++ output_name ++ "'] = " ++ "{" ++ "\n" ++
		"\t\t\t" ++ "description = " ++ output_metadata_description.quote ++ "\n" ++
		"\t\t" ++ "}"
	}.join(",\n") ++ "\n"
	"\t}"
};

var metadata = getCoreStdModuleMetadata.value();

Dialog.savePanel { |path|
	File.use(path, "w") { |file|
		file.write(formatLuaMetadata.value(metadata))
	};
	"lua metadata written to file %".format(path.quote).inform; 
};
)
