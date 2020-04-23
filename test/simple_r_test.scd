(
var inject_r_globals_path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ ".." +/+ "util" +/+ "inject_r_globals.scd").standardizePath;
this.executeFile(inject_r_globals_path);

r = ~init.value();

s.waitForBoot {
	~new.value(r, "Sound", "TestGen");
	~new.value(r, "Out", "SoundOut");
	~connect.value(r, "Sound/Out", "Out*Left");
	~connect.value(r, "Sound/Out", "Out*Right");
	~set.value(r, "Sound.Amplitude", -10);
};
)
