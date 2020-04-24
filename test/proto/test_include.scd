(
var include = { |relative_path|
	var path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ relative_path).standardizePath;
	this.executeFile(path);
};

var norns_engine_tester = include.("../util/norns_engine_tester.scd");
)
