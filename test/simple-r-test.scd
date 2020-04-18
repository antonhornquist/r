(
var inject_r_globals_path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ ".." +/+ "util" +/+ "inject-r-globals.scd").standardizePath;
this.executeFile(inject_r_globals_path);

~r_instance = ~init.value();
s.waitForBoot {
	~new.value(~r_instance, "Sound", "TestGen");
	~new.value(~r_instance, "Out", "SoundOut");
	~connect.value(~r_instance, "Sound/Out", "Out*Left");
	~connect.value(~r_instance, "Sound/Out", "Out*Right");
	~set.value(~r_instance, "Sound.Amplitude", -10);
};
)
