(
var include_relative = { |relative_path|
	var path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ relative_path).standardizePath;
	this.executeFile(path);
};

include_relative.value("test_ui.scd");
)