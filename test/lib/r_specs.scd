(
var include_relative = { |relative_path|
	var path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ relative_path).standardizePath;
	if (File.exists(path)) {
		this.executeFile(path);
	} {
		Error("include_relative: file % does not exist".format(path.quote)).throw;
	};
};

var r = include_relative.value("../../r.scd");
var getCoreStdModuleSpecs = r[\getCoreStdModuleSpecs];

getCoreStdModuleSpecs.value;
)
