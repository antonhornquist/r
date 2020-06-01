(
var include_relative = { |relative_path|
	var path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ relative_path).standardizePath;
	if (File.exists(path)) {
		this.executeFile(path);
	} {
		Error("include_relative: file % does not exist".format(path.quote)).throw;
	};
};

include_relative.value(".." +/+ "util" +/+ "inject_r_globals.scd");

r = ~init.value();

s.waitForBoot {
	~new.value(r, "Sound", "TestGen");
	~new.value(r, "Out", "SoundOut");
	~connect.value(r, "Sound/Out", "Out*Left");
	~connect.value(r, "Sound/Out", "Out*Right");
	~set.value(r, "Sound.Amplitude", -10);
};
)
