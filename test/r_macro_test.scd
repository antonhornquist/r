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
	~new.value(r, "LeftOsc", "MultiOsc");
	~new.value(r, "RightOsc", "MultiOsc");
	~new.value(r, "Out", "SoundOut");
	~set.value(r, "LeftOsc.Range", -1);
	~connect.value(r, "LeftOsc/Saw", "Out*Left");
	~connect.value(r, "RightOsc/Saw", "Out*Right");
	~newmacro.value(r, "Tune", "LeftOsc.Tune RightOsc.Tune");
	fork {
		4.do {
			~macroset.value(r, "Tune", -1200);
			1.wait;
			~macroset.value(r, "Tune", 1200);
			1.wait;
		}
	}
};
)
