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

s.waitForBoot {
	var r_instance;

	r = ~init.value();

	~new.value(r, "Trigger", "MultiLFO");
	~new.value(r, "SamplePlayer", "SPVoice");
	~new.value(r, "Out", "SoundOut");

	~connect.value(r, "Trigger/Pulse", "SamplePlayer*Gate");
	~connect.value(r, "SamplePlayer/Left", "Out*Left");
	~connect.value(r, "SamplePlayer/Right", "Out*Right");

	~readsample.value(
		r,
		"SamplePlayer:Sample",
		// "C:/my_stuff/newthing/monoe.wav"
		"C:/Users/AHorSE/OneDrive - IFS/Desktop/Life/XR-20/Hit/XR-20_533.wav"
	);

	~set.value(r, "SamplePlayer.Frequency", 440);
	~set.value(r, "SamplePlayer.LoopEnable", 1);
	~set.value(r, "SamplePlayer.SampleStart", 0);
	~set.value(r, "SamplePlayer.SampleEnd", 1);

	r_instance = r;

	CmdPeriod.doOnce {
		~free.value(r_instance);
	};
};
)
