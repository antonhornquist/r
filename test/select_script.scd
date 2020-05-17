(
var include_relative = { |relative_path|
	var path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ relative_path).standardizePath;
	this.executeFile(path);
};

var norns_engine_tester = include_relative.value("../util/norns_engine_tester.scd");
~select_script_environment = norns_engine_tester[\select_script_environment];
)
