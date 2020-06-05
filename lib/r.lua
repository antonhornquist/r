local R = {}

local ControlSpec = require 'controlspec'

local eng = {} -- NOTE: functions rely on engine global
local util = {}
local specs = {}
local metadata = {}

-- controlspecs for each module parameter. this is also available in R.metadata. R.specs is left for backwards compatilibity.

specs['44Matrix'] = {
	FadeTime = ControlSpec.new(0, 100000, "linear", 0, 5, "ms"),
	Gate_1_1 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_1_2 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_1_3 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_1_4 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_2_1 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_2_2 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_2_3 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_2_4 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_3_1 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_3_2 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_3_3 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_3_4 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_4_1 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_4_2 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_4_3 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_4_4 = ControlSpec.new(0, 1, "linear", 1, 0, "")
}

specs['88Matrix'] = {
	FadeTime = ControlSpec.new(0, 100000, "linear", 0, 5, "ms"),
	Gate_1_1 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_1_2 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_1_3 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_1_4 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_1_5 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_1_6 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_1_7 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_1_8 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_2_1 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_2_2 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_2_3 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_2_4 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_2_5 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_2_6 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_2_7 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_2_8 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_3_1 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_3_2 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_3_3 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_3_4 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_3_5 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_3_6 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_3_7 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_3_8 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_4_1 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_4_2 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_4_3 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_4_4 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_4_5 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_4_6 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_4_7 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_4_8 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_5_1 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_5_2 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_5_3 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_5_4 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_5_5 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_5_6 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_5_7 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_5_8 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_6_1 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_6_2 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_6_3 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_6_4 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_6_5 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_6_6 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_6_7 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_6_8 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_7_1 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_7_2 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_7_3 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_7_4 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_7_5 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_7_6 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_7_7 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_7_8 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_8_1 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_8_2 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_8_3 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_8_4 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_8_5 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_8_6 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_8_7 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_8_8 = ControlSpec.new(0, 1, "linear", 1, 0, "")
}

specs['ADSREnv'] = {
	Attack = ControlSpec.new(0.1, 2000, "exp", 0, 5, "ms"),
	Decay = ControlSpec.new(0.1, 8000, "exp", 0, 200, "ms"),
	Sustain = ControlSpec.new(0, 1, "linear", 0, 0.5, ""),
	Release = ControlSpec.new(0.1, 8000, "exp", 0, 200, "ms"),
	Gate = ControlSpec.new(0, 1, "linear", 1, 0, "")
}

specs['ADSREnv2'] = {
	Attack = ControlSpec.new(0.1, 2000, "exp", 0, 5, "ms"),
	Decay = ControlSpec.new(0.1, 8000, "exp", 0, 200, "ms"),
	Sustain = ControlSpec.new(0, 1, "linear", 0, 0.5, ""),
	Release = ControlSpec.new(0.1, 8000, "exp", 0, 200, "ms")
}

specs['Amp'] = {
	Level = ControlSpec.UNIPOLAR
}

specs['Amp2'] = {
	Gain = ControlSpec.UNIPOLAR,
	GainModulation = ControlSpec.BIPOLAR,
	In1 = ControlSpec.UNIPOLAR,
	In2 = ControlSpec.UNIPOLAR,
	Out = ControlSpec.UNIPOLAR,
	Mode = ControlSpec.new(0, 1, "linear", 1, 0, "")
}

specs['BPFilter'] = {
	AudioLevel = ControlSpec.new(0, 1, "amp", 0, 1, ""),
	Frequency = ControlSpec.WIDEFREQ,
	Resonance = ControlSpec.UNIPOLAR,
	FM = ControlSpec.BIPOLAR,
	ResonanceModulation = ControlSpec.BIPOLAR
}

specs['BRFilter'] = {
	AudioLevel = ControlSpec.new(0, 1, "amp", 0, 1, ""),
	Frequency = ControlSpec.WIDEFREQ,
	Resonance = ControlSpec.UNIPOLAR,
	FM = ControlSpec.BIPOLAR,
	ResonanceModulation = ControlSpec.BIPOLAR
}

specs['Comp2'] = {
	Threshold = ControlSpec.new(-math.huge, 0, "db", 0, -10, " dB"),
	Attack = ControlSpec.new(0.1, 250, "exp", 0, 10, "ms"),
	Release = ControlSpec.new(0.1, 1000, "exp", 0, 100, "ms"),
	Ratio = ControlSpec.new(0, 20, "linear", 0, 3, ""),
	MakeUp = ControlSpec.new(-math.huge, 20, "db", 0, 0, " dB")
}

specs['DbMixer'] = {
	In1 = ControlSpec.DB,
	In2 = ControlSpec.DB,
	In3 = ControlSpec.DB,
	In4 = ControlSpec.DB,
	Out = ControlSpec.DB
}

specs['Decimate'] = {
	Rate = ControlSpec.UNIPOLAR,
	Depth = ControlSpec.UNIPOLAR,
	Smooth = ControlSpec.UNIPOLAR,
	RateModulation = ControlSpec.UNIPOLAR,
	DepthModulation = ControlSpec.UNIPOLAR,
	SmoothModulation = ControlSpec.UNIPOLAR
}

specs['Delay'] = {
	DelayTime = ControlSpec.new(0.1, 5000, "exp", 0, 300, "ms"),
	DelayTimeModulation = ControlSpec.BIPOLAR
}

specs['EQBP'] = {
	Frequency = ControlSpec.WIDEFREQ,
	Bandwidth = ControlSpec.new(0, 10, "linear", 0, 0, ""),
	FM = ControlSpec.BIPOLAR,
	BandwidthModulation = ControlSpec.BIPOLAR
}

specs['EnvF'] = {
	Attack = ControlSpec.new(0.1, 2000, "exp", 0, 100, "ms"),
	Decay = ControlSpec.new(0.1, 8000, "exp", 0, 200, "ms"),
	Sensitivity = ControlSpec.new(0, 1, "linear", 0, 0.5, ""),
	Threshold = ControlSpec.new(0, 1, "linear", 0, 0.5, "")
}

specs['FMVoice'] = {
	Freq = ControlSpec.FREQ,
	Timbre = ControlSpec.new(0, 5, "linear", 0, 1, ""),
	Osc1Gain = ControlSpec.AMP,
	Osc1Partial = ControlSpec.new(0.5, 12, "linear", 0.5, 1, ""),
	Osc1Fixed = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Osc1Fixedfreq = ControlSpec.WIDEFREQ,
	Osc1Index = ControlSpec.new(0, 24, "linear", 0, 3, ""),
	Osc1Outlevel = ControlSpec.AMP,
	Osc1_To_Osc1Freq = ControlSpec.AMP,
	Osc1_To_Osc2Freq = ControlSpec.AMP,
	Osc1_To_Osc3Freq = ControlSpec.AMP,
	Osc2Gain = ControlSpec.AMP,
	Osc2Partial = ControlSpec.new(0.5, 12, "linear", 0.5, 1, ""),
	Osc2Fixed = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Osc2Fixedfreq = ControlSpec.WIDEFREQ,
	Osc2Index = ControlSpec.new(0, 24, "linear", 0, 3, ""),
	Osc2Outlevel = ControlSpec.AMP,
	Osc2_To_Osc1Freq = ControlSpec.AMP,
	Osc2_To_Osc2Freq = ControlSpec.AMP,
	Osc2_To_Osc3Freq = ControlSpec.AMP,
	Osc3Gain = ControlSpec.AMP,
	Osc3Partial = ControlSpec.new(0.5, 12, "linear", 0.5, 1, ""),
	Osc3Fixed = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Osc3Fixedfreq = ControlSpec.WIDEFREQ,
	Osc3Index = ControlSpec.new(0, 24, "linear", 0, 3, ""),
	Osc3Outlevel = ControlSpec.AMP,
	Osc3_To_Osc3Freq = ControlSpec.AMP,
	Osc3_To_Osc2Freq = ControlSpec.AMP,
	Osc3_To_Osc1Freq = ControlSpec.AMP,
	Mod_To_Osc1Gain = ControlSpec.BIPOLAR,
	Mod_To_Osc2Gain = ControlSpec.BIPOLAR,
	Mod_To_Osc3Gain = ControlSpec.BIPOLAR,
	Mod_To_Osc1Freq = ControlSpec.BIPOLAR,
	Mod_To_Osc2Freq = ControlSpec.BIPOLAR,
	Mod_To_Osc3Freq = ControlSpec.BIPOLAR
}

specs['FShift'] = {
	Frequency = ControlSpec.new(-2000, 2000, "linear", 0, 0, "Hz"),
	FM = ControlSpec.BIPOLAR
}

specs['FreqGate'] = {
	Frequency = ControlSpec.FREQ,
	Gate = ControlSpec.new(0, 1, "linear", 1, 0, "")
}

specs['HPFilter'] = {
	AudioLevel = ControlSpec.new(0, 1, "amp", 0, 1, ""),
	Frequency = ControlSpec.WIDEFREQ,
	Resonance = ControlSpec.UNIPOLAR,
	FM = ControlSpec.BIPOLAR,
	ResonanceModulation = ControlSpec.BIPOLAR
}

specs['LPFilter'] = {
	AudioLevel = ControlSpec.new(0, 1, "amp", 0, 1, ""),
	Frequency = ControlSpec.WIDEFREQ,
	Resonance = ControlSpec.UNIPOLAR,
	FM = ControlSpec.BIPOLAR,
	ResonanceModulation = ControlSpec.BIPOLAR
}

specs['LPLadder'] = {
	Frequency = ControlSpec.WIDEFREQ,
	Resonance = ControlSpec.UNIPOLAR,
	FM = ControlSpec.BIPOLAR,
	ResonanceModulation = ControlSpec.BIPOLAR
}

specs['LinMixer'] = {
	In1 = ControlSpec.UNIPOLAR,
	In2 = ControlSpec.UNIPOLAR,
	In3 = ControlSpec.UNIPOLAR,
	In4 = ControlSpec.UNIPOLAR,
	Out = ControlSpec.UNIPOLAR
}

specs['MGain'] = {
	Gain = ControlSpec.new(-math.huge, 12, "db", 0, 0, " dB"),
	Mute = ControlSpec.new(0, 1, "linear", 1, 0, "")
}

specs['MMFilter'] = {
	AudioLevel = ControlSpec.new(0, 1, "amp", 0, 1, ""),
	Frequency = ControlSpec.WIDEFREQ,
	Resonance = ControlSpec.UNIPOLAR,
	FM = ControlSpec.BIPOLAR,
	ResonanceModulation = ControlSpec.BIPOLAR
}

specs['MultiLFO'] = {
	Frequency = ControlSpec.new(0.01, 50, "exp", 0, 1, "Hz"),
	Reset = ControlSpec.new(0, 1, "linear", 1, 0, "")
}

specs['MultiOsc'] = {
	Range = ControlSpec.new(-2, 2, "linear", 1, 0, ""),
	Tune = ControlSpec.new(-600, 600, "linear", 0, 0, "cents"),
	FM = ControlSpec.UNIPOLAR,
	PulseWidth = ControlSpec.new(0, 1, "linear", 0, 0.5, ""),
	PWM = ControlSpec.UNIPOLAR
}

specs['MultiOscExp'] = {
	Range = ControlSpec.new(-2, 2, "linear", 1, 0, ""),
	Tune = ControlSpec.new(-600, 600, "linear", 0, 0, "cents"),
	FM = ControlSpec.UNIPOLAR,
	LinFM = ControlSpec.new(0, 5, "linear", 0.01, 0, ""),
	PulseWidth = ControlSpec.new(0, 1, "linear", 0, 0.5, ""),
	PWM = ControlSpec.UNIPOLAR
}

specs['Noise'] = {
}

specs['OGain'] = {
	Gain = ControlSpec.new(-math.huge, 12, "db", 0, 0, " dB"),
	Mute = ControlSpec.new(0, 1, "linear", 1, 0, "")
}

specs['PNoise'] = {
}

specs['PShift'] = {
	PitchRatio = ControlSpec.new(0, 4, "linear", 0, 1, ""),
	PitchDispersion = ControlSpec.new(0, 4, "linear", 0, 0, ""),
	TimeDispersion = ControlSpec.new(0, 1, "linear", 0, 0, ""),
	PitchRatioModulation = ControlSpec.BIPOLAR,
	PitchDispersionModulation = ControlSpec.BIPOLAR,
	TimeDispersionModulation = ControlSpec.BIPOLAR
}

specs['Pan'] = {
	Position = ControlSpec.BIPOLAR,
	PositionModulation = ControlSpec.BIPOLAR
}

specs['PolMixer'] = {
	In1 = ControlSpec.BIPOLAR,
	In2 = ControlSpec.BIPOLAR,
	In3 = ControlSpec.BIPOLAR,
	In4 = ControlSpec.BIPOLAR,
	Out = ControlSpec.UNIPOLAR
}

specs['PulseOsc'] = {
	Range = ControlSpec.new(-2, 2, "linear", 1, 0, ""),
	Tune = ControlSpec.new(-600, 600, "linear", 0, 0, "cents"),
	FM = ControlSpec.UNIPOLAR,
	PulseWidth = ControlSpec.new(0, 1, "linear", 0, 0.5, ""),
	PWM = ControlSpec.UNIPOLAR
}

specs['PulseOscExp'] = {
	Range = ControlSpec.new(-2, 2, "linear", 1, 0, ""),
	Tune = ControlSpec.new(-600, 600, "linear", 0, 0, "cents"),
	FM = ControlSpec.UNIPOLAR,
	LinFM = ControlSpec.new(0, 5, "linear", 0.01, 0, ""),
	PulseWidth = ControlSpec.new(0, 1, "linear", 0, 0.5, ""),
	PWM = ControlSpec.new(0, 1, "linear", 0, 0.4, "")
}

specs['QGain'] = {
	Gain = ControlSpec.new(-math.huge, 12, "db", 0, 0, " dB"),
	Mute = ControlSpec.new(0, 1, "linear", 1, 0, "")
}

specs['Rev1'] = {
	Volume = ControlSpec.new(-math.huge, 12, "db", 0, -10, " dB"),
	PreDelay = ControlSpec.new(1, 1000, "linear", 0, 64, "ms"),
	DelTime_1 = ControlSpec.new(64, 1000, "linear", 0, 101, "ms"),
	DelTime_2 = ControlSpec.new(64, 1000, "linear", 0, 143, "ms"),
	DelTime_3 = ControlSpec.new(64, 1000, "linear", 0, 165, "ms"),
	DelTime_4 = ControlSpec.new(64, 1000, "linear", 0, 177, "ms"),
	DelAtten_1 = ControlSpec.new(0, 0.5, "linear", 0, 0.4, ""),
	DelAtten_2 = ControlSpec.new(0, 0.5, "linear", 0, 0.37, ""),
	DelAtten_3 = ControlSpec.new(0, 0.5, "linear", 0, 0.333, ""),
	DelAtten_4 = ControlSpec.new(0, 0.5, "linear", 0, 0.3, "")
}

specs['RingMod'] = {
}

specs['SGain'] = {
	Gain = ControlSpec.new(-math.huge, 12, "db", 0, 0, " dB"),
	Mute = ControlSpec.new(0, 1, "linear", 1, 0, "")
}

specs['SPVoice'] = {
	Gate = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	SampleStart = ControlSpec.UNIPOLAR,
	SampleEnd = ControlSpec.new(0, 1, "linear", 0, 1, ""),
	LoopPoint = ControlSpec.UNIPOLAR,
	LoopEnable = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Frequency = ControlSpec.FREQ,
	RootFrequency = ControlSpec.FREQ,
	Volume = ControlSpec.new(-math.huge, 0, "db", 0, -10, " dB"),
	Pan = ControlSpec.PAN,
	FM = ControlSpec.UNIPOLAR
}

specs['SampHold'] = {
}

specs['SawOsc'] = {
	Range = ControlSpec.new(-2, 2, "linear", 1, 0, ""),
	Tune = ControlSpec.new(-600, 600, "linear", 0, 0, "cents"),
	FM = ControlSpec.UNIPOLAR
}

specs['SawOscExp'] = {
	Range = ControlSpec.new(-2, 2, "linear", 1, 0, ""),
	Tune = ControlSpec.new(-600, 600, "linear", 0, 0, "cents"),
	FM = ControlSpec.UNIPOLAR,
	LinFM = ControlSpec.new(0, 5, "linear", 0.01, 0, "")
}

specs['Seq1'] = {
	Reset = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Step = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Range = ControlSpec.new(0, 2, "linear", 1, 0, ""),
	Scale = ControlSpec.new(0, 1, "linear", 0, 1, ""),
	Glide_1 = ControlSpec.UNIPOLAR,
	Glide_2 = ControlSpec.UNIPOLAR,
	Trig_1_1 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Trig_1_2 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Trig_1_3 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Trig_1_4 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Trig_1_5 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Trig_1_6 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Trig_1_7 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Trig_1_8 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Trig_2_1 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Trig_2_2 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Trig_2_3 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Trig_2_4 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Trig_2_5 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Trig_2_6 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Trig_2_7 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Trig_2_8 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Value_1_1 = ControlSpec.BIPOLAR,
	Value_1_2 = ControlSpec.BIPOLAR,
	Value_1_3 = ControlSpec.BIPOLAR,
	Value_1_4 = ControlSpec.BIPOLAR,
	Value_1_5 = ControlSpec.BIPOLAR,
	Value_1_6 = ControlSpec.BIPOLAR,
	Value_1_7 = ControlSpec.BIPOLAR,
	Value_1_8 = ControlSpec.BIPOLAR,
	Value_2_1 = ControlSpec.BIPOLAR,
	Value_2_2 = ControlSpec.BIPOLAR,
	Value_2_3 = ControlSpec.BIPOLAR,
	Value_2_4 = ControlSpec.BIPOLAR,
	Value_2_5 = ControlSpec.BIPOLAR,
	Value_2_6 = ControlSpec.BIPOLAR,
	Value_2_7 = ControlSpec.BIPOLAR,
	Value_2_8 = ControlSpec.BIPOLAR,
	Gate_1 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_2 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_3 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_4 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_5 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_6 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_7 = ControlSpec.new(0, 1, "linear", 1, 0, ""),
	Gate_8 = ControlSpec.new(0, 1, "linear", 1, 0, "")
}

specs['SineLFO'] = {
	Frequency = ControlSpec.new(0.01, 50, "exp", 0, 1, "Hz"),
	Reset = ControlSpec.new(0, 1, "linear", 1, 0, "")
}

specs['SineOsc'] = {
	Range = ControlSpec.new(-2, 2, "linear", 1, 0, ""),
	Tune = ControlSpec.new(-600, 600, "linear", 0, 0, "cents"),
	FM = ControlSpec.UNIPOLAR
}

specs['SineOscExp'] = {
	Range = ControlSpec.new(-8, 8, "linear", 1, 0, ""),
	Tune = ControlSpec.new(-600, 600, "linear", 0, 0, "cents"),
	FM = ControlSpec.UNIPOLAR,
	LinFM = ControlSpec.new(0, 5, "linear", 0.01, 0, ""),
	PM = ControlSpec.new(0, 5, "linear", 0.01, 0, "")
}

specs['Slew'] = {
	Time = ControlSpec.new(0, 60000, "linear", 0, 0, "ms")
}

specs['SoundIn'] = {
}

specs['SoundOut'] = {
}

specs['TestGen'] = {
	Frequency = ControlSpec.WIDEFREQ,
	Amplitude = ControlSpec.DB,
	Wave = ControlSpec.new(0, 1, "linear", 1, 0, "")
}

specs['TriOsc'] = {
	Range = ControlSpec.new(-2, 2, "linear", 1, 0, ""),
	Tune = ControlSpec.new(-600, 600, "linear", 0, 0, "cents"),
	FM = ControlSpec.UNIPOLAR
}

specs['TriOscExp'] = {
	Range = ControlSpec.new(-2, 2, "linear", 1, 0, ""),
	Tune = ControlSpec.new(-600, 600, "linear", 0, 0, "cents"),
	FM = ControlSpec.UNIPOLAR,
	LinFM = ControlSpec.new(0, 5, "linear", 0.01, 0, "")
}

specs['XFader'] = {
	Fade = ControlSpec.BIPOLAR,
	TrimA = ControlSpec.new(-math.huge, 12, "db", 0, -math.huge, " dB"),
	TrimB = ControlSpec.new(-math.huge, 12, "db", 0, -math.huge, " dB"),
	Master = ControlSpec.new(-math.huge, 12, "db", 0, -math.huge, " dB")
}

-- module metadata

metadata['SoundIn'] = {
	outputs = {
		['Left'] = {
			description = "Audio signal from left R audio input."
		},
		['Right'] = {
			description = "Audio signal from right R audio input."
		}
	}
}

metadata['SoundOut'] = {
	inputs = {
		['Left'] = {
			description = "Audio signal to left R audio output."
		},
		['Right'] = {
			description = "Audio signal to right R audio output."
		}
	}
}

metadata['44Matrix'] = {
	parameters = {
		['FadeTime'] = {
			spec = ControlSpec.new(0, 1000, "linear", 0, 5, "ms"),
			description = "Fade time in milliseconds (range: `0`-`100000` ms) applied when an input is switched on to or off from an output. Default is `5` ms."
		},
		['Gate_1_1'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 1 is switched on to output 1."
		},
		['Gate_2_1'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 1 is switched on to output 2."
		},
		['Gate_3_1'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 1 is switched on to output 3."
		},
		['Gate_4_1'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 1 is switched on to output 4."
		},
		['Gate_1_2'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 2 is switched on to output 1."
		},
		['Gate_2_2'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 2 is switched on to output 2."
		},
		['Gate_3_2'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 2 is switched on to output 3."
		},
		['Gate_4_2'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 2 is switched on to output 4."
		},
		['Gate_1_3'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 3 is switched on to output 1."
		},
		['Gate_2_3'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 3 is switched on to output 2."
		},
		['Gate_3_3'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 3 is switched on to output 3."
		},
		['Gate_4_3'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 3 is switched on to output 4."
		},
		['Gate_1_4'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 4 is switched on to output 1."
		},
		['Gate_2_4'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 4 is switched on to output 2."
		},
		['Gate_3_4'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 4 is switched on to output 3."
		},
		['Gate_4_4'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 4 is switched on to output 4."
		}
	},
	inputs = {
		['In1'] = {
			description = "Input 1"
		},
		['In2'] = {
			description = "Input 2"
		},
		['In3'] = {
			description = "Input 3"
		},
		['In4'] = {
			description = "Input 4"
		}
	},
	outputs = {
		['Out1'] = {
			description = "Output 1"
		},
		['Out2'] = {
			description = "Output 2"
		},
		['Out3'] = {
			description = "Output 3"
		},
		['Out4'] = {
			description = "Output 4"
		}
	}
}

metadata['88Matrix'] = {
	parameters = {
		['FadeTime'] = {
			spec = ControlSpec.new(0, 1000, "linear", 0, 5, "ms"),
			description = "Fade time in milliseconds (range: `0`-`100000` ms) applied when an input is switched on to or off from an output. Default is `5` ms."
		},
		['Gate_1_1'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 1 is switched on to output 1."
		},
		['Gate_2_1'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 1 is switched on to output 2."
		},
		['Gate_3_1'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 1 is switched on to output 3."
		},
		['Gate_4_1'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 1 is switched on to output 4."
		},
		['Gate_5_1'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 1 is switched on to output 5."
		},
		['Gate_6_1'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 1 is switched on to output 6."
		},
		['Gate_7_1'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 1 is switched on to output 7."
		},
		['Gate_8_1'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 1 is switched on to output 8."
		},
		['Gate_1_2'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 2 is switched on to output 1."
		},
		['Gate_2_2'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 2 is switched on to output 2."
		},
		['Gate_3_2'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 2 is switched on to output 3."
		},
		['Gate_4_2'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 2 is switched on to output 4."
		},
		['Gate_5_2'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 2 is switched on to output 5."
		},
		['Gate_6_2'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 2 is switched on to output 6."
		},
		['Gate_7_2'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 2 is switched on to output 7."
		},
		['Gate_8_2'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 2 is switched on to output 8."
		},
		['Gate_1_3'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 3 is switched on to output 1."
		},
		['Gate_2_3'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 3 is switched on to output 2."
		},
		['Gate_3_3'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 3 is switched on to output 3."
		},
		['Gate_4_3'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 3 is switched on to output 4."
		},
		['Gate_5_3'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 3 is switched on to output 5."
		},
		['Gate_6_3'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 3 is switched on to output 6."
		},
		['Gate_7_3'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 3 is switched on to output 7."
		},
		['Gate_8_3'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 3 is switched on to output 8."
		},
		['Gate_1_4'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 4 is switched on to output 1."
		},
		['Gate_2_4'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 4 is switched on to output 2."
		},
		['Gate_3_4'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 4 is switched on to output 3."
		},
		['Gate_4_4'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 4 is switched on to output 4."
		},
		['Gate_5_4'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 4 is switched on to output 5."
		},
		['Gate_6_4'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 4 is switched on to output 6."
		},
		['Gate_7_4'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 4 is switched on to output 7."
		},
		['Gate_8_4'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 4 is switched on to output 8."
		},
		['Gate_1_5'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 5 is switched on to output 1."
		},
		['Gate_2_5'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 5 is switched on to output 2."
		},
		['Gate_3_5'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 5 is switched on to output 3."
		},
		['Gate_4_5'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 5 is switched on to output 4."
		},
		['Gate_5_5'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 5 is switched on to output 5."
		},
		['Gate_6_5'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 5 is switched on to output 6."
		},
		['Gate_7_5'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 5 is switched on to output 7."
		},
		['Gate_8_5'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 5 is switched on to output 8."
		},
		['Gate_1_6'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 6 is switched on to output 1."
		},
		['Gate_2_6'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 6 is switched on to output 2."
		},
		['Gate_3_6'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 6 is switched on to output 3."
		},
		['Gate_4_6'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 6 is switched on to output 4."
		},
		['Gate_5_6'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 6 is switched on to output 5."
		},
		['Gate_6_6'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 6 is switched on to output 6."
		},
		['Gate_7_6'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 6 is switched on to output 7."
		},
		['Gate_8_6'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 6 is switched on to output 8."
		},
		['Gate_1_7'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 7 is switched on to output 1."
		},
		['Gate_2_7'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 7 is switched on to output 2."
		},
		['Gate_3_7'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 7 is switched on to output 3."
		},
		['Gate_4_7'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 7 is switched on to output 4."
		},
		['Gate_5_7'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 7 is switched on to output 5."
		},
		['Gate_6_7'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 7 is switched on to output 6."
		},
		['Gate_7_7'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 7 is switched on to output 7."
		},
		['Gate_8_7'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 7 is switched on to output 8."
		},
		['Gate_1_8'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 8 is switched on to output 1."
		},
		['Gate_2_8'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 8 is switched on to output 2."
		},
		['Gate_3_8'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 8 is switched on to output 3."
		},
		['Gate_4_8'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 8 is switched on to output 4."
		},
		['Gate_5_8'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 8 is switched on to output 5."
		},
		['Gate_6_8'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 8 is switched on to output 6."
		},
		['Gate_7_8'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 8 is switched on to output 7."
		},
		['Gate_8_8'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Toggle that determine whether input 8 is switched on to output 8."
		}
	},
	inputs = {
		['In1'] = {
			description = "Input 1"
		},
		['In2'] = {
			description = "Input 2"
		},
		['In3'] = {
			description = "Input 3"
		},
		['In4'] = {
			description = "Input 4"
		},
		['In5'] = {
			description = "Input 5"
		},
		['In6'] = {
			description = "Input 6"
		},
		['In7'] = {
			description = "Input 7"
		},
		['In8'] = {
			description = "Input 8"
		}
	},
	outputs = {
		['Out1'] = {
			description = "Output 1"
		},
		['Out2'] = {
			description = "Output 2"
		},
		['Out3'] = {
			description = "Output 3"
		},
		['Out4'] = {
			description = "Output 4"
		},
		['Out5'] = {
			description = "Output 5"
		},
		['Out6'] = {
			description = "Output 6"
		},
		['Out7'] = {
			description = "Output 7"
		},
		['Out8'] = {
			description = "Output 8"
		}
	}
}

metadata['ADSREnv'] = {
	parameters = {
		['Attack'] = {
			spec = ControlSpec.new(0.1, 2000, "exp", 0, 5, "ms"),
			description = "Attack time. Range `0.1` - `2000` ms. Default is `5`."
		},
		['Decay'] = {
			spec = ControlSpec.new(0.1, 8000, "exp", 0, 200, "ms"),
			description = "Decay time. Range `0.1` - `8000` ms. Default is `200`."
		},
		['Sustain'] = {
			spec = ControlSpec.new(0, 1, "linear", 0, 0.5, ""),
			description = "Sustain level `0` - `1.0`. Default is `0.5`."
		},
		['Release'] = {
			spec = ControlSpec.new(0.1, 8000, "exp", 0, 200, "ms"),
			description = "Release time. Range `0.1` - `8000` ms. Default is `200`."
		},
		['Gate'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Scriptable gate. When parameter goes from 0 to a positive value a gate is triggered."
		}
	},
	inputs = {
		['Gate'] = {
			description = "Gate control input. A signal > 0 triggers envelope."
		}
	},
	outputs = {
		['Out'] = {
			description = "Envelope signal: `0` ... `0.8`."
		}
	}
}

metadata['ADSREnv2'] = {
	parameters = {
		['Attack'] = {
			spec = ControlSpec.new(0.1, 2000, "exp", 0, 5, "ms")
		},
		['Decay'] = {
			spec = ControlSpec.new(0.1, 8000, "exp", 0, 200, "ms")
		},
		['Sustain'] = {
			spec = ControlSpec.new(0, 1, "linear", 0, 0.5, "")
		},
		['Release'] = {
			spec = ControlSpec.new(0.1, 8000, "exp", 0, 200, "ms")
		}
	}
}

metadata['Amp'] = {
	parameters = {
		['Level'] = {
			spec = ControlSpec.UNIPOLAR,
			description = "Amplifier level `0` - `1.0`."
		}
	},
	inputs = {
		['Exp'] = {
			description = "Gain modulation control input (logarithmic)."
		},
		['Lin'] = {
			description = "Gain modulation control input (linear)."
		},
		['In'] = {
			description = "Input signal to attenuate."
		}
	},
	outputs = {
		['Out'] = {
			description = "Attenuated signal."
		}
	}
}

metadata['Amp2'] = {
	parameters = {
		['Gain'] = {
			spec = ControlSpec.UNIPOLAR,
			description = "Initial gain `0` - `1.0`."
		},
		['GainModulation'] = {
			spec = ControlSpec.BIPOLAR,
			description = "Gain modulation amount `0` - `1.0`."
		},
		['In1'] = {
			spec = ControlSpec.UNIPOLAR,
			description = "Audio input 1 level `0` - `1.0`."
		},
		['In2'] = {
			spec = ControlSpec.UNIPOLAR,
			description = "Audio input 2 level `0` - `1.0`."
		},
		['Out'] = {
			spec = ControlSpec.UNIPOLAR,
			description = "Audio output level `0` - `1.0`."
		},
		['Mode'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "`0` or `1` representing linear or exponential gain modulation."
		}
	},
	inputs = {
		['GainModulation'] = {
			description = "Control input for gain modulation."
		},
		['In1'] = {
			description = "Audio input 1."
		},
		['In2'] = {
			description = "Audio input 2."
		}
	},
	outputs = {
		['Out'] = {
			description = "Attenuated signal."
		}
	}
}

metadata['BPFilter'] = {
	parameters = {
		['AudioLevel'] = {
			spec = ControlSpec.new(0, 1, "amp", 0, 1, ""),
			description = "Audio level `0` ... `1.0`. Default is `1`."
		},
		['Frequency'] = {
			spec = ControlSpec.WIDEFREQ,
			description = "Cutoff frequency `0.1` ... `20000` Hz. Default is `440` Hz."
		},
		['Resonance'] = {
			spec = ControlSpec.UNIPOLAR,
			description = "Resonance `0` ... `1.0`. Default is `0`."
		},
		['FM'] = {
			spec = ControlSpec.BIPOLAR,
			description = "Frequency modulation amount `-1.0` ... `1.0`."
		},
		['ResonanceModulation'] = {
			spec = ControlSpec.BIPOLAR,
			description = "Resonance modulation amount `-1.0` ... `1.0`."
		}
	},
	inputs = {
		['In'] = {
			description = "Audio input."
		},
		['FM'] = {
			description = "Control input for frequency modulation."
		},
		['ResonanceModulation'] = {
			description = "Control input for resonance modulation."
		}
	},
	outputs = {
		['Out'] = {
			description = "Filtered audio signal."
		}
	}
}

metadata['BRFilter'] = {
	parameters = {
		['AudioLevel'] = {
			spec = ControlSpec.new(0, 1, "amp", 0, 1, ""),
			description = "Audio level `0` ... `1.0`. Default is `1`."
		},
		['Frequency'] = {
			spec = ControlSpec.WIDEFREQ,
			description = "Cutoff frequency `0.1` ... `20000` Hz. Default is `440` Hz."
		},
		['Resonance'] = {
			spec = ControlSpec.UNIPOLAR,
			description = "Resonance `0` ... `1.0`. Default is `0`."
		},
		['FM'] = {
			spec = ControlSpec.BIPOLAR,
			description = "Frequency modulation amount `-1.0` ... `1.0`."
		},
		['ResonanceModulation'] = {
			spec = ControlSpec.BIPOLAR,
			description = "Resonance modulation amount `-1.0` ... `1.0`."
		}
	},
	inputs = {
		['In'] = {
			description = "Audio input."
		},
		['FM'] = {
			description = "Control input for frequency modulation."
		},
		['ResonanceModulation'] = {
			description = "Control input for resonance modulation."
		}
	},
	outputs = {
		['Out'] = {
			description = "Filtered audio signal."
		}
	}
}

metadata['Comp2'] = {
	parameters = {
		['Threshold'] = {
			spec = ControlSpec.new(-math.huge, 0, "db", 0, -10, " dB"),
			description = "Treshold."
		},
		['Attack'] = {
			spec = ControlSpec.new(0.1, 250, "exp", 0, 10, "ms"),
			description = "Attack time."
		},
		['Release'] = {
			spec = ControlSpec.new(0.1, 1000, "exp", 0, 100, "ms"),
			description = "Release time."
		},
		['Ratio'] = {
			spec = ControlSpec.new(0, 20, "linear", 0, 3, ""),
			description = "Compression ratio."
		},
		['MakeUp'] = {
			spec = ControlSpec.new(-math.huge, 20, "db", 0, 0, " dB"),
			description = "Make up level."
		}
	},
	inputs = {
		['Left'] = {
			description = "Left audio input"
		},
		['Right'] = {
			description = "Right audio input."
		},
		['SideChain'] = {
			description = "Side chain control input."
		}
	},
	outputs = {
		['Left'] = {
			description = "Left compressed audio signal."
		},
		['Right'] = {
			description = "Right compressed audio signal."
		}
	}
}

metadata['DbMixer'] = {
	parameters = {
		['In1'] = {
			spec = ControlSpec.DB,
			description = "Audio input 1 level TODO: range/spec."
		},
		['In2'] = {
			spec = ControlSpec.DB,
			description = "Audio input 2 level TODO: range/spec."
		},
		['In3'] = {
			spec = ControlSpec.DB,
			description = "Audio input 3 level TODO: range/spec."
		},
		['In4'] = {
			spec = ControlSpec.DB,
			description = "Audio input 4 level TODO: range/spec."
		},
		['Out'] = {
			spec = ControlSpec.DB,
			description = "Output level TODO: range/spec."
		}
	},
	inputs = {
		['In1'] = {
			description = "Audio input 1."
		},
		['In2'] = {
			description = "Audio input 2."
		},
		['In3'] = {
			description = "Audio input 3."
		},
		['In4'] = {
			description = "Audio input 4."
		}
	},
	outputs = {
		['Out'] = {
			description = "Mixed signal."
		}
	}
}

metadata['Decimate'] = {
	parameters = {
		['Rate'] = {
			spec = ControlSpec.UNIPOLAR,
			description = "TODO."
		},
		['Depth'] = {
			spec = ControlSpec.UNIPOLAR,
			description = "TODO."
		},
		['Smooth'] = {
			spec = ControlSpec.UNIPOLAR,
			description = "TODO."
		},
		['RateModulation'] = {
			spec = ControlSpec.UNIPOLAR,
			description = "TODO."
		},
		['DepthModulation'] = {
			spec = ControlSpec.UNIPOLAR,
			description = "TODO."
		},
		['SmoothModulation'] = {
			spec = ControlSpec.UNIPOLAR,
			description = "TODO."
		}
	},
	inputs = {
		['In'] = {
			description = "Audio input."
		},
		['Rate'] = {
			description = "TODO."
		},
		['Depth'] = {
			description = "TODO."
		},
		['Smooth'] = {
			description = "TODO."
		}
	},
	outputs = {
		['Out'] = {
			description = "Reduced signal."
		}
	}
}

metadata['Delay'] = {
	parameters = {
		['DelayTime'] = {
			spec = ControlSpec.new(0.1, 5000, "exp", 0, 300, "ms"),
			description = "Delay time `0.1` ... `5000` ms."
		},
		['DelayTimeModulation'] = {
			spec = ControlSpec.BIPOLAR,
			description = "Delay time modulation amount."
		}
	},
	inputs = {
		['In'] = {
			description = "Audio input."
		},
		['DelayTimeModulation'] = {
			description = "Control signal for delay time modulation."
		}
	},
	outputs = {
		['Out'] = {
			description = "Delayed signal."
		}
	}
}

metadata['EQBP'] = {
	parameters = {
		['Frequency'] = {
			spec = ControlSpec.WIDEFREQ,
			description = "TODO"
		},
		['Bandwidth'] = {
			spec = ControlSpec.new(0, 10, "linear", 0, 0, ""),
			description = "TODO"
		},
		['FM'] = {
			spec = ControlSpec.BIPOLAR,
			description = "TODO"
		},
		['BandwidthModulation'] = {
			spec = ControlSpec.BIPOLAR,
			description = "TODO"
		}
	}
}

metadata['EnvF'] = {
	parameters = {
		['Attack'] = {
			spec = ControlSpec.new(0.1, 2000, "exp", 0, 100, "ms"),
			description = "Envelope follower attack time."
		},
		['Decay'] = {
			spec = ControlSpec.new(0.1, 8000, "exp", 0, 200, "ms"),
			description = "Envelope follower decay time."
		},
		['Sensitivity'] = {
			spec = ControlSpec.new(0, 1, "linear", 0, 0.5, ""),
			description = "Envelope follower sensitivity."
		},
		['Threshold'] = {
			spec = ControlSpec.new(0, 1, "linear", 0, 0.5, ""),
			description = "Envelope follower threshold."
		}
	},
	inputs = {
		['In'] = {
			description = "Input signal"
		}
	},
	outputs = {
		['Env'] = {
			description = "Envelope follower control output signal."
		},
		['Gate'] = {
			description = "Gte control output signal."
		}
	}
}

metadata['FMVoice'] = {
	parameters = {
		['Freq'] = {
			spec = ControlSpec.FREQ
		},
		['Timbre'] = {
			spec = ControlSpec.new(0, 5, "linear", 0, 1, "")
		},
		['Osc1Gain'] = {
			spec = ControlSpec.AMP
		},
		['Osc1Partial'] = {
			spec = ControlSpec.new(0.5, 12, "linear", 0.5, 1, "")
		},
		['Osc1Fixed'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, "")
		},
		['Osc1Fixedfreq'] = {
			spec = ControlSpec.WIDEFREQ
		},
		['Osc1Index'] = {
			spec = ControlSpec.new(0, 24, "linear", 0, 3, "")
		},
		['Osc1Outlevel'] = {
			spec = ControlSpec.AMP
		},
		['Mod_To_Osc1Freq'] = {
			spec = ControlSpec.BIPOLAR
		},
		['Mod_To_Osc1Gain'] = {
			spec = ControlSpec.BIPOLAR
		},
		['Osc1_To_Osc1Freq'] = {
			spec = ControlSpec.AMP
		},
		['Osc1_To_Osc2Freq'] = {
			spec = ControlSpec.AMP
		},
		['Osc1_To_Osc3Freq'] = {
			spec = ControlSpec.AMP
		},
		['Osc2Gain'] = {
			spec = ControlSpec.AMP
		},
		['Osc2Partial'] = {
			spec = ControlSpec.new(0.5, 12, "linear", 0.5, 1, "")
		},
		['Osc2Fixed'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, "")
		},
		['Osc2Fixedfreq'] = {
			spec = ControlSpec.WIDEFREQ
		},
		['Osc2Index'] = {
			spec = ControlSpec.new(0, 24, "linear", 0, 3, "")
		},
		['Osc2Outlevel'] = {
			spec = ControlSpec.AMP
		},
		['Mod_To_Osc2Freq'] = {
			spec = ControlSpec.BIPOLAR
		},
		['Mod_To_Osc2Gain'] = {
			spec = ControlSpec.BIPOLAR
		},
		['Osc2_To_Osc1Freq'] = {
			spec = ControlSpec.AMP
		},
		['Osc2_To_Osc2Freq'] = {
			spec = ControlSpec.AMP
		},
		['Osc2_To_Osc3Freq'] = {
			spec = ControlSpec.AMP
		},
		['Osc3Gain'] = {
			spec = ControlSpec.AMP
		},
		['Osc3Partial'] = {
			spec = ControlSpec.new(0.5, 12, "linear", 0.5, 1, "")
		},
		['Osc3Fixed'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, "")
		},
		['Osc3Fixedfreq'] = {
			spec = ControlSpec.WIDEFREQ
		},
		['Osc3Index'] = {
			spec = ControlSpec.new(0, 24, "linear", 0, 3, "")
		},
		['Osc3Outlevel'] = {
			spec = ControlSpec.AMP
		},
		['Mod_To_Osc3Freq'] = {
			spec = ControlSpec.BIPOLAR
		},
		['Mod_To_Osc3Gain'] = {
			spec = ControlSpec.BIPOLAR
		},
		['Osc3_To_Osc1Freq'] = {
			spec = ControlSpec.AMP
		},
		['Osc3_To_Osc2Freq'] = {
			spec = ControlSpec.AMP
		},
		['Osc3_To_Osc3Freq'] = {
			spec = ControlSpec.AMP
		}
	}
}

metadata['FreqGate'] = {
	parameters = {
		['Frequency'] = {
			spec = ControlSpec.FREQ,
			description = "Frequency parameter."
		},
		['Gate'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Gate parameter."
		}
	},
	outputs = {
		['Frequency'] = {
			description = "Frequency control signal."
		},
		['Gate'] = {
			description = "Gate control signal."
		},
		['Trig'] = {
			description = "Trig control signal."
		}
	}
}

metadata['FShift'] = {
	parameters = {
		['Frequency'] = {
			spec = ControlSpec.new(-2000, 2000, "linear", 0, 0, "Hz"),
			description = "Frequency shift. `-2000` Hz ... `+2000` Hz."
		},
		['FM'] = {
			spec = ControlSpec.BIPOLAR,
			description = "Frequency modulation amount. `-1.0` ... `+1.0`."
		}
	},
	inputs = {
		['Left'] = {
			description = "Left audio input."
		},
		['Right'] = {
			description = "Right audio input."
		},
		['FM'] = {
			description = "Control signal for frequency shift modulation."
		}
	},
	outputs = {
		['Left'] = {
			description = "Left shifted signal."
		},
		['Right'] = {
			description = "Right shifted signal."
		}
	}
}

metadata['HPFilter'] = {
	parameters = {
		['AudioLevel'] = {
			spec = ControlSpec.new(0, 1, "amp", 0, 1, ""),
			description = "Audio level `0` ... `1.0`. Default is `1`."
		},
		['Frequency'] = {
			spec = ControlSpec.WIDEFREQ,
			description = "Cutoff frequency `0.1` ... `20000` Hz. Default is `440` Hz."
		},
		['Resonance'] = {
			spec = ControlSpec.UNIPOLAR,
			description = "Resonance `0` ... `1.0`. Default is `0`."
		},
		['FM'] = {
			spec = ControlSpec.BIPOLAR,
			description = "Frequency modulation amount `-1.0` ... `1.0`."
		},
		['ResonanceModulation'] = {
			spec = ControlSpec.BIPOLAR,
			description = "Resonance modulation amount `-1.0` ... `1.0`."
		}
	},
	inputs = {
		['In'] = {
			description = "Audio input."
		},
		['FM'] = {
			description = "Control input for frequency modulation."
		},
		['ResonanceModulation'] = {
			description = "Control input for resonance modulation."
		}
	},
	outputs = {
		['Out'] = {
			description = "Filtered audio signal."
		}
	}
}

metadata['LinMixer'] = {
	parameters = {
		['In1'] = {
			spec = ControlSpec.UNIPOLAR,
			description = "Audio input 1 level TODO: range/spec."
		},
		['In2'] = {
			spec = ControlSpec.UNIPOLAR,
			description = "Audio input 2 level TODO: range/spec."
		},
		['In3'] = {
			spec = ControlSpec.UNIPOLAR,
			description = "Audio input 3 level TODO: range/spec."
		},
		['In4'] = {
			spec = ControlSpec.UNIPOLAR,
			description = "Audio input 4 level TODO: range/spec."
		},
		['Out'] = {
			spec = ControlSpec.UNIPOLAR,
			description = "Output level TODO: range/spec."
		}
	},
	inputs = {
		['In1'] = {
			description = "Audio input 1."
		},
		['In2'] = {
			description = "Audio input 2."
		},
		['In3'] = {
			description = "Audio input 3."
		},
		['In4'] = {
			description = "Audio input 4."
		}
	},
	outputs = {
		['Out'] = {
			description = "Mixed signal."
		}
	}
}

metadata['LPFilter'] = {
	parameters = {
		['AudioLevel'] = {
			spec = ControlSpec.new(0, 1, "amp", 0, 1, ""),
			description = "Audio level `0` ... `1.0`. Default is `1`."
		},
		['Frequency'] = {
			spec = ControlSpec.WIDEFREQ,
			description = "Cutoff frequency `0.1` ... `20000` Hz. Default is `440` Hz."
		},
		['Resonance'] = {
			spec = ControlSpec.UNIPOLAR,
			description = "Resonance `0` ... `1.0`. Default is `0`."
		},
		['FM'] = {
			spec = ControlSpec.BIPOLAR,
			description = "Frequency modulation amount `-1.0` ... `1.0`."
		},
		['ResonanceModulation'] = {
			spec = ControlSpec.BIPOLAR,
			description = "Resonance modulation amount `-1.0` ... `1.0`."
		}
	},
	inputs = {
		['In'] = {
			description = "Audio input."
		},
		['FM'] = {
			description = "Control input for frequency modulation."
		},
		['ResonanceModulation'] = {
			description = "Control input for resonance modulation."
		}
	},
	outputs = {
		['Out'] = {
			description = "Filtered audio signal."
		}
	}
}

metadata['LPLadder'] = {
	parameters = {
		['Frequency'] = {
			spec = ControlSpec.WIDEFREQ,
			description = "Cutoff frequency `0.1` ... `20000` Hz. Default is `440` Hz."
		},
		['Resonance'] = {
			spec = ControlSpec.UNIPOLAR,
			description = "Resonance `0` ... `1.0`. Default is `0`."
		},
		['FM'] = {
			spec = ControlSpec.BIPOLAR,
			description = "Frequency modulation amount `-1.0` ... `1.0`."
		},
		['ResonanceModulation'] = {
			spec = ControlSpec.BIPOLAR,
			description = "Resonance modulation amount `-1.0` ... `1.0`."
		}
	},
	inputs = {
		['In'] = {
			description = "Audio input."
		},
		['FM'] = {
			description = "Control input for frequency modulation."
		},
		['ResonanceModulation'] = {
			description = "Control input for resonance modulation."
		}
	},
	outputs = {
		['Out'] = {
			description = "Filtered audio signal."
		}
	}
}

metadata['MGain'] = {
	parameters = {
		['Gain'] = {
			spec = ControlSpec.new(-math.huge, 12, "db", 0, 0, " dB"),
			description = "Attenuation control. `-inf` ... `+12` dB."
		},
		['Mute'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "If `1` signal is muted, otherwise not."
		}
	},
	inputs = {
		['In'] = {
			description = "Audio input."
		}
	},
	outputs = {
		['Out'] = {
			description = "Attenuated audio signal."
		}
	}
}

metadata['MMFilter'] = {
	parameters = {
		['AudioLevel'] = {
			spec = ControlSpec.new(0, 1, "amp", 0, 1, ""),
			description = "Audio level `0` ... `1.0`. Default is `1`."
		},
		['Frequency'] = {
			spec = ControlSpec.WIDEFREQ,
			description = "Cutoff frequency `0.1` ... `20000` Hz. Default is `440` Hz."
		},
		['Resonance'] = {
			spec = ControlSpec.UNIPOLAR,
			description = "Resonance `0` ... `1.0`. Default is `0`."
		},
		['FM'] = {
			spec = ControlSpec.BIPOLAR,
			description = "Frequency modulation amount `-1.0` ... `1.0`."
		},
		['ResonanceModulation'] = {
			spec = ControlSpec.BIPOLAR,
			description = "Resonance modulation amount `-1.0` ... `1.0`."
		}
	},
	inputs = {
		['In'] = {
			description = "Audio input."
		},
		['FM'] = {
			description = "Control input for frequency modulation."
		},
		['ResonanceModulation'] = {
			description = "Control input for resonance modulation."
		}
	},
	outputs = {
		['Notch'] = {
			description = "Band-reject filtered audio signal."
		},
		['Highpass'] = {
			description = "Highpass filtered audio signal."
		},
		['Bandpass'] = {
			description = "Bandpass filtered audio signal."
		},
		['Lowpass'] = {
			description = "Lowpass filtered audio signal."
		}
	}
}

metadata['MultiLFO'] = {
	parameters = {
		['Frequency'] = {
			spec = ControlSpec.new(0.01, 50, "exp", 0, 1, "Hz"),
			description = "LFO Frequency `0.01` Hz ... `50` Hz."
		},
		['Reset'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Manual LFO reset trigger."
		}
	},
	inputs = {
		['Reset'] = {
			description = "Audio rate reset trigger: when signal is changed from 0 to 1 the LFO is retriggered."
		}
	},
	outputs = {
		['InvSaw'] = {
			description = "Inverted saw signal output."
		},
		['Saw'] = {
			description = "Saw signal output."
		},
		['Sine'] = {
			description = "Sine signal output."
		},
		['Triangle'] = {
			description = "Triangle signal output."
		},
		['Pulse'] = {
			description = "Pulse signal output."
		}
	}
}

metadata['MultiOsc'] = {
	parameters = {
		['Range'] = {
			spec = ControlSpec.new(-2, 2, "linear", 1, 0, ""),
			description = "`-2` ... `+2` octaves."
		},
		['Tune'] = {
			spec = ControlSpec.new(-600, 600, "linear", 0, 0, "cents"),
			description = "`-1200` ... `+1200` cents."
		},
		['PulseWidth'] = {
			spec = ControlSpec.new(0, 1, "linear", 0, 0.5, ""),
			description = "Pulse oscillator pulse width."
		},
		['FM'] = {
			spec = ControlSpec.UNIPOLAR,
			description = "Frequency modulation amount."
		},
		['PWM'] = {
			spec = ControlSpec.UNIPOLAR,
			description = "Pulse width modulation amount."
		}
	},
	inputs = {
		['FM'] = {
			description = "Control signal for frequency modulation."
		},
		['PWM'] = {
			description = "Control signal for pulse width modulation."
		}
	},
	outputs = {
		['Sine'] = {
			description = "Sine wave oscillator output."
		},
		['Triangle'] = {
			description = "Triangle wave oscillator output."
		},
		['Saw'] = {
			description = "Saw wave oscillator output."
		},
		['Pulse'] = {
			description = "Pulse wave oscillator output."
		}
	}
}

metadata['MultiOscExp'] = {
	parameters = {
		['Range'] = {
			spec = ControlSpec.new(-2, 2, "linear", 1, 0, ""),
			description = "`-2` ... `+2` octaves."
		},
		['Tune'] = {
			spec = ControlSpec.new(-600, 600, "linear", 0, 0, "cents"),
			description = "`-1200` ... `+1200` cents."
		},
		['PulseWidth'] = {
			spec = ControlSpec.new(0, 1, "linear", 0, 0.5, ""),
			description = "Pulse oscillator pulse width."
		},
		['FM'] = {
			spec = ControlSpec.UNIPOLAR,
			description = "Frequency modulation amount."
		},
		['LinFM'] = {
			spec = ControlSpec.new(0, 10000, "linear", 0, 0, "Hz"),
			description = "Linear frequency modulation amount."
		},
		['PWM'] = {
			spec = ControlSpec.UNIPOLAR,
			description = "Pulse width modulation amount."
		}
	},
	inputs = {
		['FM'] = {
			description = "Control signal for frequency modulation."
		},
		['LinFM'] = {
			description = "Control signal for linear frequency modulation."
		},
		['PWM'] = {
			description = "Control signal for pulse width modulation."
		}
	},
	outputs = {
		['Sine'] = {
			description = "Sine wave oscillator output."
		},
		['Triangle'] = {
			description = "Triangle wave oscillator output."
		},
		['Saw'] = {
			description = "Saw wave oscillator output."
		},
		['Pulse'] = {
			description = "Pulse wave oscillator output."
		}
	}
}

metadata['Noise'] = {
	outputs = {
		['Out'] = {
			description = "Noise signal."
		}
	}
}

metadata['OGain'] = {
	parameters = {
		['Gain'] = {
			spec = ControlSpec.new(-math.huge, 12, "db", 0, 0, " dB"),
			description = "Attenuation control. `-inf` ... `+12` dB."
		},
		['Mute'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "If `1` signal is muted, otherwise not."
		}
	},
	inputs = {
		['In1'] = {
			description = "Audio input 1."
		},
		['In2'] = {
			description = "Audio input 2."
		},
		['In3'] = {
			description = "Audio input 3."
		},
		['In4'] = {
			description = "Audio input 4."
		},
		['In5'] = {
			description = "Audio input 5."
		},
		['In6'] = {
			description = "Audio input 6."
		},
		['In7'] = {
			description = "Audio input 7."
		},
		['In8'] = {
			description = "Audio input 8."
		}
	},
	outputs = {
		['Out1'] = {
			description = "Attenuated audio signal output 1."
		},
		['Out2'] = {
			description = "Attenuated audio signal output 2."
		},
		['Out3'] = {
			description = "Attenuated audio signal output 3."
		},
		['Out4'] = {
			description = "Attenuated audio signal output 4."
		},
		['Out5'] = {
			description = "Attenuated audio signal output 5."
		},
		['Out6'] = {
			description = "Attenuated audio signal output 6."
		},
		['Out7'] = {
			description = "Attenuated audio signal output 7."
		},
		['Out8'] = {
			description = "Attenuated audio signal output 8."
		}
	}
}

metadata['Pan'] = {
	parameters = {
		['Position'] = {
			spec = ControlSpec.BIPOLAR,
			description = "Pan position `-1.0` ... `1.0` referring to left ... right panning."
		},
		['PositionModulation'] = {
			spec = ControlSpec.BIPOLAR,
			description = "Pan position modulation amount `-1.0` ... `1.0`."
		}
	},
	inputs = {
		['In'] = {
			description = "Mono audio signal."
		},
		['PositionModulation'] = {
			description = "Right audio signal."
		}
	},
	outputs = {
		['Left'] = {
			description = "Left audio signal."
		},
		['Right'] = {
			description = "Right audio signal."
		}
	}
}

metadata['PolMixer'] = {
	parameters = {
		['In1'] = {
			spec = ControlSpec.BIPOLAR,
			description = "Audio input 1 level TODO: range/spec."
		},
		['In2'] = {
			spec = ControlSpec.BIPOLAR,
			description = "Audio input 2 level TODO: range/spec."
		},
		['In3'] = {
			spec = ControlSpec.BIPOLAR,
			description = "Audio input 3 level TODO: range/spec."
		},
		['In4'] = {
			spec = ControlSpec.BIPOLAR,
			description = "Audio input 4 level TODO: range/spec."
		},
		['Out'] = {
			spec = ControlSpec.UNIPOLAR,
			description = "Output level TODO: range/spec."
		}
	},
	inputs = {
		['In1'] = {
			description = "Audio input 1."
		},
		['In2'] = {
			description = "Audio input 2."
		},
		['In3'] = {
			description = "Audio input 3."
		},
		['In4'] = {
			description = "Audio input 4."
		}
	},
	outputs = {
		['Out'] = {
			description = "Mixed signal."
		}
	}
}

metadata['PNoise'] = {
	outputs = {
		['Out'] = {
			description = "Noise signal."
		}
	}
}

metadata['PShift'] = {
	parameters = {
		['PitchRatio'] = {
			spec = ControlSpec.new(0, 4, "linear", 0, 1, ""),
			description = "Pitch ratio: `0` ... `4`. Default is `1`."
		},
		['PitchDispersion'] = {
			spec = ControlSpec.new(0, 4, "linear", 0, 0, ""),
			description = "Pitch dispersion: `0` ... `4`. Default is `0`."
		},
		['TimeDispersion'] = {
			spec = ControlSpec.new(0, 1, "linear", 0, 0, ""),
			description = "Time dispersion: `0` ... `1`. Default is `0`."
		},
		['PitchRatioModulation'] = {
			spec = ControlSpec.BIPOLAR,
			description = "Pitch ratio modulation amount: `-1` ... `1`."
		},
		['PitchDispersionModulation'] = {
			spec = ControlSpec.BIPOLAR,
			description = "Pitch dispersion modulation amount: `-1` ... `1`."
		},
		['TimeDispersionModulation'] = {
			spec = ControlSpec.BIPOLAR,
			description = "Time dispersion modulation amount: `-1` ... `1`."
		}
	},
	inputs = {
		['Left'] = {
			description = "Left audio signal."
		},
		['Right'] = {
			description = "Right audio signal."
		},
		['PitchRatioModulation'] = {
			description = "Pitch ratio modulation amount."
		},
		['PitchDispersionModulation'] = {
			description = "Pitch dispersion modulation amount."
		},
		['TimeDispersionModulation'] = {
			description = "Time dispersion modulation amount."
		}
	},
	outputs = {
		['Left'] = {
			description = "Left processed audio signal."
		},
		['Right'] = {
			description = "Right processed audio signal."
		}
	}
}

metadata['PulseOsc'] = {
	parameters = {
		['Range'] = {
			spec = ControlSpec.new(-2, 2, "linear", 1, 0, ""),
			description = "`-2` ... `+2` octaves."
		},
		['Tune'] = {
			spec = ControlSpec.new(-600, 600, "linear", 0, 0, "cents"),
			description = "`-1200` ... `+1200` cents."
		},
		['PulseWidth'] = {
			spec = ControlSpec.new(0, 1, "linear", 0, 0.5, ""),
			description = "Pulse oscillator Pulse width."
		},
		['FM'] = {
			spec = ControlSpec.UNIPOLAR,
			description = "Frequency modulation amount."
		},
		['PWM'] = {
			spec = ControlSpec.new(0, 1, "linear", 0, 0.4, ""),
			description = "Pulse width modulation amount."
		}
	},
	inputs = {
		['FM'] = {
			description = "Control signal for frequency modulation."
		},
		['PWM'] = {
			description = "Control signal for pulse width modulation."
		}
	},
	outputs = {
		['Out'] = {
			description = "Pulse wave oscillator output."
		}
	}
}

metadata['PulseOscExp'] = {
	parameters = {
		['Range'] = {
			spec = ControlSpec.new(-2, 2, "linear", 1, 0, ""),
			description = "`-2` ... `+2` octaves."
		},
		['Tune'] = {
			spec = ControlSpec.new(-600, 600, "linear", 0, 0, "cents"),
			description = "`-1200` ... `+1200` cents."
		},
		['PulseWidth'] = {
			spec = ControlSpec.new(0, 1, "linear", 0, 0.5, ""),
			description = "Pulse oscillator pulse width."
		},
		['FM'] = {
			spec = ControlSpec.UNIPOLAR,
			description = "Frequency modulation amount."
		},
		['PWM'] = {
			spec = ControlSpec.new(0, 1, "linear", 0, 0.4, ""),
			description = "Pulse width modulation amount."
		},
		['LinFM'] = {
			spec = ControlSpec.new(0, 10000, "linear", 0, 0, "Hz"),
			description = "Linear frequency modulation amount."
		}
	},
	inputs = {
		['FM'] = {
			description = "Control signal for frequency modulation."
		},
		['LinFM'] = {
			description = "Control signal for linear frequency modulation."
		},
		['PWM'] = {
			description = "Control signal for pulse width modulation."
		}
	},
	outputs = {
		['Out'] = {
			description = "Pulse wave oscillator output."
		}
	}
}

metadata['QGain'] = {
	parameters = {
		['Gain'] = {
			spec = ControlSpec.new(-math.huge, 12, "db", 0, 0, " dB"),
			description = "Attenuation control. `-inf` ... `+12` dB."
		},
		['Mute'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "If `1` signal is muted, otherwise not."
		}
	},
	inputs = {
		['In1'] = {
			description = "Audio input 1"
		},
		['In2'] = {
			description = "Audio input 2"
		},
		['In3'] = {
			description = "Audio input 3"
		},
		['In4'] = {
			description = "Audio input 4"
		}
	},
	outputs = {
		['Out1'] = {
			description = "Attenuated audio signal output 1."
		},
		['Out2'] = {
			description = "Attenuated audio signal output 2."
		},
		['Out3'] = {
			description = "Attenuated audio signal output 3."
		},
		['Out4'] = {
			description = "Attenuated audio signal output 4."
		}
	}
}

metadata['Rev1'] = {
	parameters = {
		['Volume'] = {
			spec = ControlSpec.new(-math.huge, 12, "db", 0, -10, " dB")
		},
		['PreDelay'] = {
			spec = ControlSpec.new(1, 1000, "linear", 0, 64, "ms")
		},
		['DelTime_1'] = {
			spec = ControlSpec.new(64, 1000, "linear", 0, 101, "ms")
		},
		['DelTime_2'] = {
			spec = ControlSpec.new(64, 1000, "linear", 0, 143, "ms")
		},
		['DelTime_3'] = {
			spec = ControlSpec.new(64, 1000, "linear", 0, 165, "ms")
		},
		['DelTime_4'] = {
			spec = ControlSpec.new(64, 1000, "linear", 0, 177, "ms")
		},
		['DelAtten_1'] = {
			spec = ControlSpec.new(0, 0.5, "linear", 0, 0.4, "")
		},
		['DelAtten_2'] = {
			spec = ControlSpec.new(0, 0.5, "linear", 0, 0.37, "")
		},
		['DelAtten_3'] = {
			spec = ControlSpec.new(0, 0.5, "linear", 0, 0.333, "")
		},
		['DelAtten_4'] = {
			spec = ControlSpec.new(0, 0.5, "linear", 0, 0.3, "")
		}
	}
}

metadata['RingMod'] = {
	inputs = {
		['In'] = {
			description = "Audio signal input."
		},
		['Carrier'] = {
			description = "Carrier signal input."
		}
	},
	outputs = {
		['Out'] = {
			description = "Ring modulated audio signal."
		}
	}
}

metadata['SampHold'] = {
	inputs = {
		['In'] = {
			description = "Audio signal input."
		},
		['Trig'] = {
			description = "Trigger signal input."
		}
	},
	outputs = {
		['Out'] = {
			description = "Processed audio signal."
		}
	}
}

metadata['SawOsc'] = {
	parameters = {
		['Range'] = {
			spec = ControlSpec.new(-2, 2, "linear", 1, 0, ""),
			description = "`-2` ... `+2` octaves."
		},
		['Tune'] = {
			spec = ControlSpec.new(-600, 600, "linear", 0, 0, "cents"),
			description = "`-1200` ... `+1200` cents."
		},
		['FM'] = {
			spec = ControlSpec.UNIPOLAR,
			description = "Frequency modulation amount."
		}
	},
	inputs = {
		['FM'] = {
			description = "Control signal for frequency modulation."
		}
	},
	outputs = {
		['Out'] = {
			description = "Saw wave oscillator output."
		}
	}
}

metadata['SawOscExp'] = {
	parameters = {
		['Range'] = {
			spec = ControlSpec.new(-2, 2, "linear", 1, 0, ""),
			description = "`-2` ... `+2` octaves."
		},
		['Tune'] = {
			spec = ControlSpec.new(-600, 600, "linear", 0, 0, "cents"),
			description = "`-1200` ... `+1200` cents."
		},
		['FM'] = {
			spec = ControlSpec.UNIPOLAR,
			description = "Frequency modulation amount."
		},
		['LinFM'] = {
			spec = ControlSpec.new(0, 10000, "linear", 0, 0, "Hz"),
			description = "Linear frequency modulation amount."
		}
	},
	inputs = {
		['FM'] = {
			description = "Control signal for frequency modulation."
		},
		['LinFM'] = {
			description = "Control signal for linear frequency modulation."
		}
	},
	outputs = {
		['Out'] = {
			description = "Saw wave oscillator output."
		}
	}
}

metadata['Seq1'] = {
	parameters = {
		['Reset'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Manual reset."
		},
		['Step'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Manual forward step."
		},
		['Range'] = {
			spec = ControlSpec.new(0, 2, "linear", 1, 0, ""),
			description = "Output range: `0`, `1` or `2`, specifying ranges `0.1`, `0.2`, `0.4` respectively."
		},
		['Scale'] = {
			spec = ControlSpec.new(0, 1, "linear", 0, 1, ""),
			description = "TODO"
		},
		['Glide_1'] = {
			spec = ControlSpec.UNIPOLAR,
			description = "Glide time 1."
		},
		['Glide_2'] = {
			spec = ControlSpec.UNIPOLAR,
			description = "Glide time 2."
		},
		['Trig_1_1'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Tigger for row 1 step 1"
		},
		['Trig_1_2'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Tigger for row 1 step 2"
		},
		['Trig_1_3'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Tigger for row 1 step 3"
		},
		['Trig_1_4'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Tigger for row 1 step 4"
		},
		['Trig_1_5'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Tigger for row 1 step 5"
		},
		['Trig_1_6'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Tigger for row 1 step 6"
		},
		['Trig_1_7'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Tigger for row 1 step 7"
		},
		['Trig_1_8'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Tigger for row 1 step 8"
		},
		['Value_1_1'] = {
			spec = ControlSpec.BIPOLAR,
			description = "Value for row 1 step 1"
		},
		['Value_1_2'] = {
			spec = ControlSpec.BIPOLAR,
			description = "Value for row 1 step 2"
		},
		['Value_1_3'] = {
			spec = ControlSpec.BIPOLAR,
			description = "Value for row 1 step 3"
		},
		['Value_1_4'] = {
			spec = ControlSpec.BIPOLAR,
			description = "Value for row 1 step 4"
		},
		['Value_1_5'] = {
			spec = ControlSpec.BIPOLAR,
			description = "Value for row 1 step 5"
		},
		['Value_1_6'] = {
			spec = ControlSpec.BIPOLAR,
			description = "Value for row 1 step 6"
		},
		['Value_1_7'] = {
			spec = ControlSpec.BIPOLAR,
			description = "Value for row 1 step 7"
		},
		['Value_1_8'] = {
			spec = ControlSpec.BIPOLAR,
			description = "Value for row 1 step 8"
		},
		['Trig_2_1'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Tigger for row 2 step 1"
		},
		['Trig_2_2'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Tigger for row 2 step 2"
		},
		['Trig_2_3'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Tigger for row 2 step 3"
		},
		['Trig_2_4'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Tigger for row 2 step 4"
		},
		['Trig_2_5'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Tigger for row 2 step 5"
		},
		['Trig_2_6'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Tigger for row 2 step 6"
		},
		['Trig_2_7'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Tigger for row 2 step 7"
		},
		['Trig_2_8'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Tigger for row 2 step 8"
		},
		['Value_2_1'] = {
			spec = ControlSpec.BIPOLAR,
			description = "Value for row 2 step 1"
		},
		['Value_2_2'] = {
			spec = ControlSpec.BIPOLAR,
			description = "Value for row 2 step 2"
		},
		['Value_2_3'] = {
			spec = ControlSpec.BIPOLAR,
			description = "Value for row 2 step 3"
		},
		['Value_2_4'] = {
			spec = ControlSpec.BIPOLAR,
			description = "Value for row 2 step 4"
		},
		['Value_2_5'] = {
			spec = ControlSpec.BIPOLAR,
			description = "Value for row 2 step 5"
		},
		['Value_2_6'] = {
			spec = ControlSpec.BIPOLAR,
			description = "Value for row 2 step 6"
		},
		['Value_2_7'] = {
			spec = ControlSpec.BIPOLAR,
			description = "Value for row 2 step 7"
		},
		['Value_2_8'] = {
			spec = ControlSpec.BIPOLAR,
			description = "Value for row 2 step 8"
		},
		['Gate_1'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Gate for step 1"
		},
		['Gate_2'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Gate for step 2"
		},
		['Gate_3'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Gate for step 3"
		},
		['Gate_4'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Gate for step 4"
		},
		['Gate_5'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Gate for step 5"
		},
		['Gate_6'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Gate for step 6"
		},
		['Gate_7'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Gate for step 7"
		},
		['Gate_8'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Gate for step 8"
		}
	},
	inputs = {
		['Clock'] = {
			description = "Clock input."
		},
		['Reset'] = {
			description = "Reset input."
		},
		['SampleAndHoldCtrl1'] = {
			description = "Sample and hold control 1."
		},
		['GlideCtrl1'] = {
			description = "Glide control input 1."
		},
		['SampleAndHoldCtrl2'] = {
			description = "Sample and hold control 2."
		},
		['GlideCtrl2'] = {
			description = "Glide control input 2."
		}
	},
	outputs = {
		['Trig1'] = {
			description = "Trigger output 1."
		},
		['Trig2'] = {
			description = "Trigger output 2."
		},
		['Gate'] = {
			description = "Gate output."
		},
		['PreOut1'] = {
			description = "Pre-output 1."
		},
		['Out1'] = {
			description = "Output 1."
		},
		['PreOut2'] = {
			description = "Pre-output 2."
		},
		['Out2'] = {
			description = "Output 2."
		}
	}
}

metadata['SGain'] = {
	parameters = {
		['Gain'] = {
			spec = ControlSpec.new(-math.huge, 12, "db", 0, 0, " dB"),
			description = "Attenuation control. `-inf` ... `+12` dB."
		},
		['Mute'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "If `1` signal is muted, otherwise not."
		}
	},
	inputs = {
		['Left'] = {
			description = "Left channel input."
		},
		['Right'] = {
			description = "Right channel input."
		}
	},
	outputs = {
		['Left'] = {
			description = "Attenuated left channel signal."
		},
		['Right'] = {
			description = "Attenuated right channel signal."
		}
	}
}

metadata['SineLFO'] = {
	parameters = {
		['Frequency'] = {
			spec = ControlSpec.new(0.01, 50, "exp", 0, 1, "Hz"),
			description = "Frequency `0.01` Hz .. `50` Hz."
		},
		['Reset'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Script reset trigger: when value is changed from `0` to `1` the LFO is retriggered."
		}
	},
	inputs = {
		['Reset'] = {
			description = "Audio rate reset trigger: when signal is changed from 0 to 1 the LFO is retriggered."
		}
	},
	outputs = {
		['Out'] = {
			description = "Sine output"
		}
	}
}

metadata['SineOsc'] = {
	parameters = {
		['Range'] = {
			spec = ControlSpec.new(-2, 2, "linear", 1, 0, ""),
			description = "`-2` ... `+2` octaves."
		},
		['Tune'] = {
			spec = ControlSpec.new(-600, 600, "linear", 0, 0, "cents"),
			description = "`-1200` ... `+1200` cents."
		},
		['FM'] = {
			spec = ControlSpec.UNIPOLAR,
			description = "Frequency modulation amount."
		}
	},
	inputs = {
		['FM'] = {
			description = "Control signal for frequency modulation."
		}
	},
	outputs = {
		['Out'] = {
			description = "Sine wave oscillator output."
		}
	}
}

metadata['SineOscExp'] = {
	parameters = {
		['Range'] = {
			spec = ControlSpec.new(-2, 2, "linear", 1, 0, ""),
			description = "`-2` ... `+2` octaves."
		},
		['Tune'] = {
			spec = ControlSpec.new(-600, 600, "linear", 0, 0, "cents"),
			description = "`-1200` ... `+1200` cents."
		},
		['FM'] = {
			spec = ControlSpec.UNIPOLAR,
			description = "Frequency modulation amount."
		},
		['LinFM'] = {
			spec = ControlSpec.new(0, 10000, "linear", 0, 0, "Hz"),
			description = "Linear frequency modulation amount."
		},
		['PM'] = {
			spec = ControlSpec.new(0, 5, "linear", 0.01, 0, ""),
			description = "Phase modulation amount."
		}
	},
	inputs = {
		['FM'] = {
			description = "Control signal for frequency modulation."
		},
		['LinFM'] = {
			description = "Control signal for linear frequency modulation."
		},
		['PM'] = {
			description = "Control signal for phase modulation."
		}
	},
	outputs = {
		['Out'] = {
			description = "Sine wave oscillator output."
		}
	}
}

metadata['Slew'] = {
	parameters = {
		['Time'] = {
			spec = ControlSpec.new(0, 60000, "linear", 0, 0, "ms"),
			description = "Slew time `0` ... `60 000` ms."
		}
	},
	inputs = {
		['In'] = {
			description = "Audio signal imput."
		}
	},
	outputs = {
		['Out'] = {
			description = "Processed audio signal."
		}
	}
}

metadata['SPVoice'] = {
	parameters = {
		['Gate'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Manual gate."
		},
		['SampleStart'] = {
			spec = ControlSpec.UNIPOLAR,
			description = "Sample start position normalized to `0` ... `1`."
		},
		['SampleEnd'] = {
			spec = ControlSpec.new(0, 1, "linear", 0, 1, ""),
			description = "Sample end position normalized to `0` ... `1`."
		},
		['LoopPoint'] = {
			spec = ControlSpec.UNIPOLAR,
			description = "Loop point within sample start and end position normalized to `0` ... `1`."
		},
		['LoopEnable'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Loop enabled. `1` means enabled, `0` not."
		},
		['Frequency'] = {
			spec = ControlSpec.FREQ,
			description = "Frequency."
		},
		['RootFrequency'] = {
			spec = ControlSpec.FREQ,
			description = "Root frequency."
		},
		['Volume'] = {
			spec = ControlSpec.new(-math.huge, 0, "db", 0, -10, " dB"),
			description = "Volume."
		},
		['Pan'] = {
			spec = ControlSpec.PAN,
			description = "Pan position."
		},
		['FM'] = {
			spec = ControlSpec.UNIPOLAR,
			description = "Frequency modulation amount."
		}
	},
	inputs = {
		['Gate'] = {
			description = "Control signal for gate"
		},
		['FM'] = {
			description = "Control signal for frequency modulation"
		}
	},
	outputs = {
		['Left'] = {
			description = "Left audio signal"
		},
		['Right'] = {
			description = "Right audio signal"
		}
	}
}

metadata['TestGen'] = {
	parameters = {
		['Frequency'] = {
			spec = ControlSpec.WIDEFREQ,
			description = "Sine wave frequency."
		},
		['Amplitude'] = {
			spec = ControlSpec.DB,
			description = "Audio output signal amplitude."
		},
		['Wave'] = {
			spec = ControlSpec.new(0, 1, "linear", 1, 0, ""),
			description = "Wave: `0` means sine wave, `1` white noise."
		}
	},
	outputs = {
		['Out'] = {
			description = "Sine wave signal or noise output."
		}
	}
}

metadata['TriOsc'] = {
	parameters = {
		['Range'] = {
			spec = ControlSpec.new(-2, 2, "linear", 1, 0, ""),
			description = "`-2` ... `+2` octaves."
		},
		['Tune'] = {
			spec = ControlSpec.new(-600, 600, "linear", 0, 0, "cents"),
			description = "`-1200` ... `+1200` cents."
		},
		['FM'] = {
			spec = ControlSpec.UNIPOLAR,
			description = "Frequency modulation amount."
		}
	},
	inputs = {
		['FM'] = {
			description = "Control signal for frequency modulation."
		}
	},
	outputs = {
		['Out'] = {
			description = "Triangle wave oscillator output."
		}
	}
}

metadata['TriOscExp'] = {
	parameters = {
		['Range'] = {
			spec = ControlSpec.new(-2, 2, "linear", 1, 0, ""),
			description = "`-2` ... `+2` octaves."
		},
		['Tune'] = {
			spec = ControlSpec.new(-600, 600, "linear", 0, 0, "cents"),
			description = "`-1200` ... `+1200` cents."
		},
		['FM'] = {
			spec = ControlSpec.UNIPOLAR,
			description = "Frequency modulation amount."
		},
		['LinFM'] = {
			spec = ControlSpec.new(0, 10000, "linear", 0, 0, "Hz"),
			description = "Linear frequency modulation amount."
		}
	},
	inputs = {
		['FM'] = {
			description = "Control signal for frequency modulation."
		},
		['LinFM'] = {
			description = "Control signal for linear frequency modulation."
		}
	},
	outputs = {
		['Out'] = {
			description = "Triangle wave oscillator output."
		}
	}
}

metadata['XFader'] = {
	parameters = {
		['Fade'] = {
			spec = ControlSpec.BIPOLAR,
			description = "Fader position: `-1` fully attenuates stereo signal A, `1` fully attenuates stereo signal B, anything in between mixes the signals."
		},
		['TrimA'] = {
			spec = ControlSpec.new(-math.huge, 12, "db", 0, -math.huge, " dB"),
			description = "Signal A trim."
		},
		['TrimB'] = {
			spec = ControlSpec.new(-math.huge, 12, "db", 0, -math.huge, " dB"),
			description = "Signal B trim."
		},
		['Master'] = {
			spec = ControlSpec.new(-math.huge, 12, "db", 0, -math.huge, " dB"),
			description = "Master output level."
		}
	},
	inputs = {
		['InALeft'] = {
			description = "Signal A left audio signal."
		},
		['InARight'] = {
			description = "Signal A right audio signal."
		},
		['InBLeft'] = {
			description = "Signal B left audio signal."
		},
		['InBRight'] = {
			description = "Signal B right audio signal."
		}
	},
	outputs = {
		['Left'] = {
			description = "Crossfaded left audio signal."
		},
		['Right'] = {
			description = "Crossfaded right audio signal."
		}
	}
}

-- utility function to create module, will validate kind lua side
function eng.new(name, kind)
  if specs[kind] then
    engine.new(name..voicenum, kind)
  else
    error(kind.." - not a valid module type")
  end
end

-- utility function to create multiple modules suffixed 1..polyphony
function eng.poly_new(name, kind, polyphony)
  if specs[kind] then
    for voicenum=1, polyphony do
      engine.new(name..voicenum, kind)
    end
  else
    error(kind.." not a valid module type")
  end
end

-- utility function to connect modules suffixed with 1..polyphony
function eng.poly_connect(output, input, polyphony)
  local sourcemodule, outputref = util.split_ref(output)
  local destmodule, inputref = util.split_ref(input)
  for voicenum=1, polyphony do
    engine.connect(sourcemodule..voicenum.."/"..outputref, destmodule..voicenum.."*"..inputref)
  end
end

-- utility function to set param of multiple modules suffixed 1..polyphony
function eng.poly_set(ref, value, polyphony)
  local module, param = util.split_ref(ref)
  for voicenum=1, polyphony do
    engine.set(util.param_voice_ref(module, param, voicenum), value)
  end
end

-- utility function to expand a moduleparam ref to #polyphony ones suffixed with 1..polyphony
function util.poly_expand(moduleparam, polyphony)
  local module, param = util.split_ref(moduleparam)
  local expanded = ""

  for voicenum=1, polyphony do
    expanded = expanded .. util.param_voice_ref(module, param, voicenum)
    if voicenum ~= polyphony then
      expanded = expanded .. " "
    end
  end

  return expanded
end

function util.param_voice_ref(module, param, voicenum)
  return module .. voicenum .. "." .. param
end

function util.split_ref(ref)
  local words = {}
  for word in ref:gmatch("[a-zA-Z0-9]+") do table.insert(words, word) end
  return words[1], words[2]
end

R.specs = specs
R.metadata = metadata
R.engine = eng
R.util = util

return R
