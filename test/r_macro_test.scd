(
var inject_r_globals_path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ ".." +/+ "util" +/+ "inject_r_globals.scd").standardizePath;
this.executeFile(inject_r_globals_path);

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
