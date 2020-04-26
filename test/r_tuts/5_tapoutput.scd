(
s.waitForBoot {
	r=Rrrr.new
};
)

r.newCommand("FreqGate", "FreqGate");
r.newCommand("LFO", "MultiLFO");
r.newCommand("Env", "ADSREnv");
r.newCommand("FilterMod", "LinMixer");
r.newCommand("Osc", "PulseOsc");
r.newCommand("Filter", "MMFilter");
r.newCommand("Amp", "Amp");
r.newCommand("SoundOut", "SoundOut");

r.setCommand("Osc.FM", 1);

r.connectCommand("FreqGate/Frequency", "Osc*FM");
r.connectCommand("FreqGate/Gate", "Env*Gate");
r.connectCommand("LFO/Sine", "Osc*PWM");
r.connectCommand("LFO/Sine", "FilterMod*In1");
r.connectCommand("Env/Out", "FilterMod*In2");
r.connectCommand("Env/Out", "Amp*Lin");
r.connectCommand("FilterMod/Out", "Filter*FM");

r.connectCommand("Osc/Out", "Filter*In");
r.connectCommand("Filter/Lowpass", "Amp*In");
r.connectCommand("Amp/Out", "SoundOut*Left");
r.connectCommand("Amp/Out", "SoundOut*Right");

r.tapoutletCommand(0, "LFO/Sine");

r.setCommand("FilterMod.Out", 1)
r.setCommand("Filter.FM", 1)

r.setCommand("FreqGate.Gate", 1)
r.setCommand("FreqGate.Gate", 0)

r.setCommand("FreqGate.Frequency", 120)

r.setCommand("Osc.Tune", 0)
r.setCommand("LFO.Frequency", 4)
r.setCommand("Osc.PulseWidth", 0.2)
r.setCommand("Osc.PWM", 0)
r.setCommand("Env.Attack", 1000)
r.setCommand("Env.Decay", 0)
r.setCommand("Env.Sustain", 0)
r.setCommand("Env.Release", 2000)
r.setCommand("Filter.Frequency", 1000)
r.setCommand("Filter.Resonance", 0)
r.setCommand("FilterMod.In1", 0)
r.setCommand("FilterMod.In2", 0)
