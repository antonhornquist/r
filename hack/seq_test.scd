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
	r = ~init.value();

	~new.value(r, "LFO", "MultiLFO");
	~set.value(r, "LFO.Frequency", 0.05);

	~new.value(r, "Resetter", "MultiLFO");
	~set.value(r, "Resetter.Frequency", 0.4);

	~new.value(r, "Clock", "MultiLFO");
	~set.value(r, "Clock.Frequency", 7);

	~new.value(r, "Seq", "Seq1");
	~set.value(r, "Seq.Range", 1);
	~set.value(r, "Seq.Glide_1", 0.25);
	~set.value(r, "Seq.Scale", 1);

	~new.value(r, "Osc1", "MultiOsc");
	~set.value(r, "Osc1.Range", 0);
	~set.value(r, "Osc1.FM", 1);
	~set.value(r, "Osc1.PulseWidth", 0.2);
	~set.value(r, "Osc1.PWM", 1);

	~new.value(r, "Osc2", "MultiOsc");
	~set.value(r, "Osc2.Range", 0);
	~set.value(r, "Osc2.Tune", -10);
	~set.value(r, "Osc2.FM", 1);

	~new.value(r, "Env", "ADSREnv");
	~set.value(r, "Env.Attack", 0);
	~set.value(r, "Env.Decay", 250);
	~set.value(r, "Env.Sustain", 0.25);
	~set.value(r, "Env.Release", 250);

	~new.value(r, "Filter", "MMFilter");
	~set.value(r, "Filter.Frequency", 200);
	~set.value(r, "Filter.Resonance", 0.3);
	~set.value(r, "Filter.FM", 0.3);

	~new.value(r, "Amp", "Amp");

	~new.value(r, "Out", "SoundOut");

	~connect.value(r, "Clock/Pulse", "Seq*Clock");
	~connect.value(r, "Resetter/Pulse", "Seq*Reset");

	~connect.value(r, "LFO/Sine", "Osc1*PWM");
	~connect.value(r, "Seq/Out1", "Osc1*FM");
	~connect.value(r, "Seq/PreOut2", "Osc1*PWM");
	~connect.value(r, "Seq/Out1", "Osc2*FM");
	~connect.value(r, "Seq/PreOut2", "Osc2*PWM");

	~connect.value(r, "Seq/Trig1", "Env*Gate");
	~connect.value(r, "LFO/Sine", "Filter*FM");

	~connect.value(r, "Osc1/Pulse", "Filter*In");
	~connect.value(r, "Osc2/Saw", "Filter*In");

	~connect.value(r, "Filter/Lowpass", "Amp*In");
	~connect.value(r, "Env/Out", "Amp*Lin");
	~connect.value(r, "Env/Out", "Filter*FM");
	~connect.value(r, "Amp/Out", "Out*Left");
	~connect.value(r, "Amp/Out", "Out*Right");
	~connect.value(r, "Seq/Trig1", "Seq*SampleAndHoldCtrl1");
	~connect.value(r, "Seq/Gate", "Seq*GlideCtrl1");

	~set.value(r, "Seq.Trig_1_1", 1);
	~set.value(r, "Seq.Gate_1", 0);
	~set.value(r, "Seq.Value_1_1", 1);
	~set.value(r, "Seq.Value_2_1", 1);

/*
	~set.value(r, "Seq.Trig_1_2", 1);
	~set.value(r, "Seq.Gate_2", 1);
	~set.value(r, "Seq.Value_1_2", 0.2);
	~set.value(r, "Seq.Value_2_2", 1);
*/

	~set.value(r, "Seq.Trig_1_3", 1);
	~set.value(r, "Seq.Gate_3", 1);
	~set.value(r, "Seq.Value_1_3", 0.5);
	~set.value(r, "Seq.Value_2_3", 0.5);

	~set.value(r, "Seq.Trig_1_4", 1);
	~set.value(r, "Seq.Value_1_4", 1);
	~set.value(r, "Seq.Value_2_4", 0.25);

	~set.value(r, "Seq.Trig_1_5", 1);
	~set.value(r, "Seq.Value_1_5", 0.5);

	~set.value(r, "Seq.Trig_1_6", 1);
	~set.value(r, "Seq.Value_1_6", -0.1);
	~set.value(r, "Seq.Value_2_6", 0.75);

	~set.value(r, "Seq.Gate_7", 1);
	~set.value(r, "Seq.Trig_1_7", 1);
	~set.value(r, "Seq.Value_1_7", -1);
	~set.value(r, "Seq.Value_2_7", 0.95);

	~set.value(r, "Seq.Gate_8", 1);
	~set.value(r, "Seq.Trig_1_8", 1);
	~set.value(r, "Seq.Value_1_8", -0.5);
	~set.value(r, "Seq.Value_2_8", -0.5);

	CmdPeriod.doOnce {
		~free.value(r, false); // TODO: server nodes are already freed by CmdPeriod logic
	};
};
)
