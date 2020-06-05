(
var r_path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ ".." +/+ "r.scd").standardizePath;
var r = this.executeFile(r_path);
var getCoreStdModuleMetadata = r[\getCoreStdModuleMetadata];

var formatLuaMetadata = { |r_module_metadata_array|
	r_module_metadata_array.collect { |r_module_metadata|
		var module_name = r_module_metadata.key;

		"specs['"++module_name.asString++"'] = {\n"++
			if (r_module_metadata[\parameters].isNil) {
				""
			} {
				r_module_metadata[\parameters].collect { |r_param_metadata| // TODO: report error when controlSpec is not found / or rely on .asSpec
					var param_name = r_param_metadata.key;
					var param_metadata_content = r_param_metadata.value;
					var param_metadata_spec = param_metadata_content[\Spec];
						
					"\t" ++ param_name ++ " = " ++ if (param_metadata_spec.class == Symbol) {
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
					}
				}.join(",\n") ++ "\n"
			} ++
		"}" ++ "\n";
	};
};

var metadata = getCoreStdModuleMetadata.value();

postcs(formatLuaMetadata.value(metadata));
)
