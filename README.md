---
---

# R

General purpose audio patching engine

## Features

- Arbitrarily create and connect audio generators and processors (_modules_).
- Control module parameters from Lua scripting layer.

## Disclaimer

- Take care of your ears and speakers while patching. 🎹🎛️🎧

## Commands

- `new ss <modulename> <moduletype>` - creates a uniquely named module of given type (refer to section "Modules" for available types).
	- Examples: `new Osc MultiOsc`, `new Out SoundOut`
- `connect ss <modulename/output> <modulename*input>` - connects a module output to a module input. *
	- Examples: `connect Osc/Pulse Out*Left`, `connect Osc/Pulse Out*Right`
- `disconnect ss <modulename/output> <modulename*input>` - disconnects a module output from a module input. *
	- Example: `disconnect Osc/Out Out*Left`
- `set sf <modulename.parameter> <value>` - sets a module parameter to the given value.
	- Examples: `set Osc.Tune -13`, `set Osc.PulseWidth 0.5`
- `delete s <modulename>` - removes a module.
	- Example: `delete Osc`

* In an earlier version inputs were referred to with the same delimiter as outputs `<modulename/input>`. This still works but is deprecated. For clarity, it is advised to use the new delimiter `<modulename*input>`.

### Bulk Commands

- `bulkset s <bundle>` - sets multiple module parameters to values given a bundle of `modulename.parameter` `value` pairs serialized as a string.
	- Example: `bulkset "Osc.Tune -1 Osc.PulseWidth 0.7"` has the same effect as sending `set Osc.Tune -1` and `set Osc.PulseWidth 0.7`. All value changes of a bundle are performed at the same time. TODO: floating point precision?

### Macro Commands

- `newmacro ss <macroname> <modulename.parameters...>` - creates a uniquely named macro for simultaneous control of a list of space delimited module parameters. All included parameters should adhere to the same spec.
	- Example: given `SineOsc` and `PulseOsc` modules named `Osc1` and `Osc2` the command `newmacro Tune "Osc1.Tune Osc2.Tune"` defines a new macro controlling `Tune` parameter for both modules.
- `macroset sf <macroname> <value>` - sets value for module parameters included in a macro. Controlling multiple parameters with a macro is more efficient than using multiple `set` commands. It is also faster than using `bulkset`. All value changes of parameters in a macro are performed at the same time.
	- Example: given `Tune` macro above command `macroset Tune 30` has the same effect as commands `set Osc1.Tune 30` and `set Osc2.Tune 30`.
- `deletemacro s <macroname>` - removes a macro.
	- Example: `deletemacro Tune`.

### Polls

The engine has ten polls named `poll1` to `poll10`. Snapshots of module output signals can be routed to these polls. In addition, some modules expose feedback values typically used for visualization (ie. the `MMFilter` module feedback value `Frequency` which takes frequency modulation into account). These values - referred to as _visuals_ - can also be routed to the polls.

- `polloutput is <modulename/output>` - routes an output signal of a named module to a poll.
	- Examples: `pollvisual 1 LFO/Saw` routes the signal of the output named Saw of the LFO module to `poll1`.

- `pollvisual is <modulename=visual>` - routes a visual of a named module to a poll.
	- Example: `pollvisual 2 Filter=Frequency` routes the feedback value of the visual named Frequency of the Filter module to `poll2`.

Only one output or visual can be routed to each poll at any given time. The latest routed output or visual takes precedence.

### Debug Commands

- `trace i <boolean>` - determines whether to post debug output in SCLang Post Window (`1` = yes, `0` = no)

## Modules

### 44Matrix

4x4 matrix signal router

- Inputs:
	- `In1` ... `In4`: Signal inputs
- Outputs:
	- `In1` ... `In4`: Signal outputs
- Parameters:
	- `FadeTime`: Fade time in milliseconds (range: 0-100000 ms) applied when an input is switched on to or off from an output. Default is 5 ms.
	- `Gate_1_1` ... `Gate_4_4`: Toggles that determine whether inputs (first number) are switched on to outputs (second number).

### 88Matrix

8x8 matrix signal router

- Inputs:
	- `In1` ... `In8`: Signal inputs
- Outputs:
	- `In1` ... `In8`: Signal outputs
- Parameters:
	- `FadeTime`: Fade time in milliseconds (range: 0-100000 ms) applied when an input is switched on to or off from an output. Default is 5 ms.
	- `Gate_1_1` ... `Gate_8_8`: Toggles that determine whether inputs (first number) are switched on to outputs (second number).

### ADSREnv

ADSR Envelope.

- Inputs:
	- `Gate`: Gate control input. A signal > 0 triggers envelope
- Outputs:
	- `Out`: Envelope signal: 0 ... 0.8.
- Parameters:
	- `Attack`: Attack time. Range 0.1 - 2000 ms. Default is 5.
	- `Decay`: Decay time. Range 0.1 - 8000 ms. Default is 200.
	- `Sustain`: Sustain level 0 - 1.0. Default is 0.5.
	- `Release`: Release time. Range 0.1 - 8000 ms. Default is 200.
	- `Gate`: Scriptable gate. When parameter goes from 0 to a positive value a gate is triggered.

### Amp

Simple amplifier with level parameter and exponential or linear gain modulation.

- Inputs:
	- `Exp`: Gain modulation control input (logarithmic)
	- `Lin`: Gain modulation control input (linear)
	- `In`: Input signal to attenuate
- Outputs:
	- `Out`: Attenuated output signal
- Parameters:
	- `Level`: Amplifier level 0 - 1.0.

### Amp2

Amplifier with two inputs, level parameter and variable exponential or linear gain modulation.

- Inputs:
	- `GainModulation`: Control input for gain modulation
	- `In1`: Audio input 1
	- `In2`: Audio input 2
- Outputs:
	- `Out`: Attenuated signal
- Parameters:
	- `Gain`: Initial gain 0 - 1.0.
	- `GainModulation`: Gain modulation amount 0 - 1.0.
	- `In1`: Audio input 1 level 0 - 1.0.
	- `In2`: Audio input 2 level 0 - 1.0.
	- `Out`: Audio output level 0 - 1.0.
	- `Mode`: 0 or 1 representing linear or exponential gain modulation.

### BPFilter

Bandpass SVF filter.

- Inputs:
	- `In`: Audio input
	- `FM`: Control input for frequency modulation
	- `ResonanceModulation`: Control input for resonance modulation
- Outputs:
	- `Out`: Filtered audio output
- Parameters:
	- `AudioLevel`: Audio level 0 ... 1.0. Default is 1.
	- `Frequency`: Cutoff frequency 0.1 ... 20000 Hz. Default is 440 Hz.
	- `Resonance`: Resonance 0 ... 1.0. Default is 0.
	- `FM`: Frequency modulation amount -1.0 ... 1.0.
	- `ResonanceModulation`: Resonance modulation amount -1.0 ... 1.0.

### BRFilter

Bandreject (Notch) SVF filter.

- Inputs:
	- `In`: Audio input
	- `FM`: Control input for frequency modulation
	- `ResonanceModulation`: Control input for resonance modulation
- Outputs:
	- `Out`: Filtered audio output
- Parameters:
	- `AudioLevel`: Audio level 0 ... 1.0. Default is 1.
	- `Frequency`: Cutoff frequency 0.1 ... 20000 Hz. Default is 440 Hz.
	- `Resonance`: Resonance 0 ... 1.0. Default is 0.
	- `FM`: Frequency modulation amount -1.0 ... 1.0.
	- `ResonanceModulation`: Resonance modulation amount -1.0 ... 1.0.

### DbMixer

Mixer suited for audio signals.

- Inputs:
	- `In1` ... `In4`: Audio inputs 1 ... 4
- Outputs:
	- `Out`: Mixed signal
- Parameters:
	- `In1`: Audio input 1 level TODO: range/spec
	- `In2`: Audio input 2 level TODO: range/spec
	- `In3`: Audio input 3 level TODO: range/spec
	- `In4`: Audio input 4 level TODO: range/spec
	- `Out`: Output level TODO: range/spec

### Delay

Delay line.

- Inputs:
	- `In`: Audio input
	- `DelayTimeModulation`: Control input for delay time modulation
- Outputs:
	- `Out`: Delayed signal
- Parameters:
	- `DelayTime`: Delay time TODO
	- `DelayTimeModulation`: Delay time modulation TODO

### FMVoice

FM voice (TODO: untested)

- Inputs:
	- `Modulation`
- Outputs:
	- `Out`
- Parameters:
	- `Freq`
	- `Timbre`
	- `Osc1Gain`
	- `Osc1Partial`
	- `Osc1Fixed`
	- `Osc1Fixedfreq`
	- `Osc1Index`
	- `Osc1Outlevel`
	- `Osc1_To_Osc1Freq`
	- `Osc1_To_Osc2Freq`
	- `Osc1_To_Osc3Freq`
	- `Osc2Gain`
	- `Osc2Partial`
	- `Osc2Fixed`
	- `Osc2Fixedfreq`
	- `Osc2Index`
	- `Osc2Outlevel`
	- `Osc2_To_Osc1Freq`
	- `Osc2_To_Osc2Freq`
	- `Osc2_To_Osc3Freq`
	- `Osc3Gain`
	- `Osc3Partial`
	- `Osc3Fixed`
	- `Osc3Fixedfreq`
	- `Osc3Index`
	- `Osc3Outlevel`
	- `Osc3_To_Osc3Freq`
	- `Osc3_To_Osc2Freq`
	- `Osc3_To_Osc1Freq`
	- `Mod_To_Osc1Gain`
	- `Mod_To_Osc2Gain`
	- `Mod_To_Osc3Gain`
	- `Mod_To_Osc1Freq`
	- `Mod_To_Osc2Freq`
	- `Mod_To_Osc3Freq`

### FShift

Frequency shifter.

- Inputs:
	- `Left`: Left audio input
	- `Right`: Right audio input
	- `FM`: Control signal for frequency modulation
- Outputs:
	- `Left`: Frequency shifted audio output (left)
	- `Right`: Frequency shifted audio output (right)
- Parameters:
	- `Frequency`: Frequency shift. -2000 Hz ... +2000 Hz
	- `FM`: Frequency modulation amount. -1.0 ... +1.0

### FreqGate

CV/Gate thing.

- Inputs: None
- Outputs:
	- `Frequency`: 
	- `Gate`: 
	- `Trig`: 
- Parameters:
	- `Frequency`: 
	- `Gate`: 

### HPFilter

Highpass SVF filter.

- Inputs:
	- `In`: Audio input
	- `FM`: Control input for frequency modulation
	- `ResonanceModulation`: Control input for resonance modulation
- Outputs:
	- `Out`: Filtered audio output
- Parameters:
	- `AudioLevel`: Audio level 0 ... 1.0. Default is 1.
	- `Frequency`: Cutoff frequency 0.1 ... 20000 Hz. Default is 440 Hz.
	- `Resonance`: Resonance 0 ... 1.0. Default is 0.
	- `FM`: Frequency modulation amount -1.0 ... 1.0.
	- `ResonanceModulation`: Resonance modulation amount -1.0 ... 1.0.

### LPFilter

Lowpass SVF filter.

- Inputs:
	- `In`: Audio input
	- `FM`: Control input for frequency modulation
	- `ResonanceModulation`: Control input for resonance modulation
- Outputs:
	- `Out`: Filtered audio output
- Parameters:
	- `AudioLevel`: Audio level 0 ... 1.0. Default is 1.
	- `Frequency`: Cutoff frequency 0.1 ... 20000 Hz. Default is 440 Hz.
	- `Resonance`: Resonance 0 ... 1.0. Default is 0.
	- `FM`: Frequency modulation amount -1.0 ... 1.0.
	- `ResonanceModulation`: Resonance modulation amount -1.0 ... 1.0.

### LPLadder

Lowpass ladder filter.

- Inputs:
	- `In`: Audio input
	- `FM`: Control input for frequency modulation
	- `ResonanceModulation`: Control input for resonance modulation
- Outputs:
	- `Out`: Filtered audio output
- Parameters:
	- `Frequency`: Cutoff frequency 0.1 ... 20000 Hz. Default is 440 Hz.
	- `Resonance`: Resonance 0 ... 1.0. Default is 0.
	- `FM`: Frequency modulation amount -1.0 ... 1.0.
	- `ResonanceModulation`: Resonance modulation amount -1.0 ... 1.0.

### LinMixer

Mixer suited for control signals

- Inputs:
	- `In1` ... `In4`: Audio inputs 1 ... 4
- Outputs:
	- `Out`: Mixed signal
- Parameters:
	- `In1`: Audio input 1 level TODO: range/spec
	- `In2`: Audio input 2 level TODO: range/spec
	- `In3`: Audio input 3 level TODO: range/spec
	- `In4`: Audio input 4 level TODO: range/spec
	- `Out`: Output level TODO: range/spec

### MGain

Audio fader with db gain control and mute.

- Inputs:
	- `In`: Audio input
- Outputs:
	- `Out`: Attenuated audio output
- Parameters:
	- `Gain`: Attenuation control. -inf ... +12 dB
	- `Mute`: If 1 signal is muted, otherwise not

### MMFilter

Multimode filter.

- Inputs:
	- `In`: Audio input
	- `FM`: Control input for frequency modulation
	- `ResonanceModulation`: Control input for resonance modulation
- Outputs:
	- `Notch`: Band-reject filtered audio output
	- `Highpass`: Highpass filtered audio output
	- `Bandpass`: Bandpass filtered audio output
	- `Lowpass`: Lowpass filtered audio output
- Parameters:
	- `AudioLevel`: Audio level 0 ... 1.0. Default is 1.
	- `Frequency`: Cutoff frequency 0.1 ... 20000 Hz. Default is 440 Hz.
	- `Resonance`: Resonance 0 ... 1.0. Default is 0.
	- `FM`: Frequency modulation amount -1.0 ... 1.0.
	- `ResonanceModulation`: Resonance modulation amount -1.0 ... 1.0.

### MultiLFO

LFO featuring multiple waveforms.

- Inputs:
	- `Reset`: Audio rate reset trigger: when signal is changed from 0 to 1 the LFO is retriggered
- Outputs:
	- `InvSaw`: Inverted saw signal output
	- `Saw`: Upward saw signal output
	- `Sine`: Sine signal output
	- `Triangle`: Triange signal output
	- `Pulse`: Pulse signal output
- Parameters:
	- `Frequency`: Frequency 0.01 Hz .. 50 Hz
	- `Reset`: Script reset trigger: when value is changed from 0 to 1 the LFO is retriggered

### MultiOsc

Oscillator featuring multiple waveforms.

- Inputs:
	- `FM`: Control signal input for frequency modulation
	- `PWM`: Control signal input for pulse width modulation
- Outputs:
	- `Sine`: Sine wave oscillator output
	- `Triangle`: Triangle wave oscillator output
	- `Saw`: Sawtooth wave oscillator output
	- `Pulse`: Pulse wave oscillator output
- Parameters:
	- `Range`: -2 ... +2 octaves.
	- `Tune`: -1200 ... +1200 cents
	- `FM`: Frequency modulation amount
	- `PulseWidth`: Pulse width of the pulse oscillator output
	- `PWM`: Pulse width modulation amount

### Noise

White noise generator.

- Inputs: None
- Outputs:
	- `Out`: White noise output
- Parameters: None

### OGain

8-in/8-out audio fader with db gain control and mute.

- Inputs:
	- `In1` ... `In8`: Audio inputs
- Outputs:
	- `Out1` ... `Out8`: Attenuated audio outputs
- Parameters:
	- `Gain`: Attenuation control. -inf ... +12 dB
	- `Mute`: If 1 signal is muted, otherwise not

### PShift

Pitch shifter.

- Inputs:
	- `Left`: Right audio input
	- `Right`: Right audio input
	- `PitchRatioModulation`
	- `PitchDispersionModulation`
	- `TimeDispersionModulation`
- Outputs:
	- `Left`: Left audio output
	- `Right`: Right audio output
- Parameters:
	- `PitchRatio`
	- `PitchDispersion`
	- `TimeDispersion`
	- `PitchRatioModulation`
	- `PitchDispersionModulation`
	- `TimeDispersionModulation`

### PulseOsc

Pulse/square oscillator with pulse width control.

- Inputs:
	- `FM`: Control signal input for frequency modulation
	- `PWM`: Control signal input for pulse width modulation
- Outputs:
	- `Out`: Pulse wave oscillator output
- Parameters:
	- `Range`: -2 ... +2 octaves.
	- `Tune`: -1200 ... +1200 cents
	- `FM`: Frequency modulation amount
	- `PulseWidth`: Pulse width of the pulse oscillator output
	- `PWM`: Pulse width modulation amount

### QGain

4-in/4-out audio fader with db gain control and mute.

- Inputs:
	- `In1` ... `In4`: Audio inputs
- Outputs:
	- `Out1` ... `Out4`: Attenuated audio outputs
- Parameters:
	- `Gain`: Attenuation control. -inf ... +12 dB
	- `Mute`: If 1 signal is muted, otherwise not

### RingMod

Ring modulator.

- Inputs:
	- `In`
	- `Carrier`
- Outputs:
	- `Out`
- Parameters: None

### SGain

2-in/2-out audio fader with db gain control and mute.

- Inputs:
	- `Left`: Left audio input
	- `Right`: Right audio input
- Outputs:
	- `Left`: Left audio output
	- `Right`: Right audio output
- Parameters:
	- `Gain`: Attenuation control. -inf ... +12 dB
	- `Mute`: If 1 signal is muted, otherwise not

### SampHold

Sample and hold module.

- Inputs:
	- `In`
	- `Trig`
- Outputs:
	- `Out`
- Parameters: None

### SawOsc

Sawtooth oscillator.

- Inputs:
	- `FM`: Control signal input for frequency modulation
	- `PWM`: Control signal input for pulse width modulation
- Outputs:
	- `Out`: Sawtooth wave oscillator output
- Parameters:
	- `Range`: -2 ... +2 octaves.
	- `Tune`: -1200 ... +1200 cents
	- `FM`: Frequency modulation amount

### SineLFO

Sine LFO.

- Inputs:
	- `Reset`: Audio rate reset trigger: when signal is changed from 0 to 1 the LFO is retriggered
- Outputs:
	- `Out`: Sine signal output
- Parameters:
	- `Frequency`: Frequency 0.01 Hz .. 50 Hz
	- `Reset`: Script reset trigger: when value is changed from 0 to 1 the LFO is retriggered

### SineOsc

Sine oscillator.

- Inputs:
	- `FM`: Control signal input for frequency modulation
	- `PWM`: Control signal input for pulse width modulation
- Outputs:
	- `Out`: Sine wave oscillator output
- Parameters:
	- `Range`: -2 ... +2 octaves.
	- `Tune`: -1200 ... +1200 cents
	- `FM`: Frequency modulation amount

### SoundIn

- Inputs: None
- Outputs:
	- `Left`: Left audio signal from external audio input
	- `Right`: Right audio signal from external audio input
- Parameters: None

### SoundOut

- Inputs:
	- `Left`: Left audio signal sent to external audio output
	- `Right`: Left audio signal sent to external audio output
- Outputs: None
- Parameters: None

### TestGen

- Inputs: None
- Outputs:
	- `Out`: Test signal output
- Parameters:
	- `Frequency`: Sine oscillator frequency
	- `Amplitude`: Amplitude
	- `Wave`: TODO

### TriOsc

Triangle oscillator (non-bandlimited).

- Inputs:
	- `FM`: Control signal input for frequency modulation
	- `PWM`: Control signal input for pulse width modulation
- Outputs:
	- `Out`: Triangle wave oscillator output
- Parameters:
	- `Range`: -2 ... +2 octaves.
	- `Tune`: -1200 ... +1200 cents
	- `FM`: Frequency modulation amount

### XFader

Crossfader

- Inputs:
	- `InALeft`
	- `InARight`
	- `InBLeft`
	- `InBRight`
- Outputs:
	- `Left`
	- `Right`
- Parameters:
	- `Fade`
	- `TrimA`
	- `TrimB`
	- `Master`

## Example Usage

``` lua
-- Spawn three modules
engine.new("LFO", "MultiLFO")
engine.new("Osc", "PulseOsc")
engine.new("SoundOut", "SoundOut")

-- Modulate OSC pulse width by LFO sine wave
engine.connect("LFO/Sine", "Osc*PWM")

-- Hook up oscillator to audio outputs
engine.connect("Osc/Out", "SoundOut*Left")
engine.connect("Osc/Out", "SoundOut*Right")

-- Set module parameter values
engine.set("Osc.PulseWidth", 0.25)
engine.set("LFO.Frequency", 0.5)
engine.set("Osc.PWM", 0.2)
```

See tutorial scripts in [r_tuts](http://github.com/antonhornquist/r_tuts) and [roar scripts](http://github.com/antonhornquist/roar) `moln`, `rymd`, `bob` and `skev` for more elaborate examples.

## The R Lua Module

The R Lua module contains:
- Default specs for all included modules.
- A number of convenience functions for working with the R engine (polyphonic set ups and more).
- Other utility functions.

Require the R module:

``` lua
local R = require 'r/lib/r'
```

### Module Specs

`R.specs` contains default specs for all modules, ie.:

``` lua
R.specs.MultiOsc.Tune -- returns ControlSpec.new(-600, 600, "linear", 0, 0, "cents")
```

These can be copied and overriden, if needed:

``` lua
local my_testgen_spec = R.specs.TestGen.Frequency:copy() -- returns ControlSpec.WIDEFREQ
my_testgen_spec.minval = 80
my_testgen_spec.maxval = 8000
```

### Engine Functions

``` lua
R.engine.poly_new("Osc", "MultiOsc", 3) -- creates MultiOsc modules Osc1, Osc2 and Osc3
R.engine.poly_new("Filter", "MMFilter", 3) -- creates MMFilter modules Filter1, Filter2 and Filter3

R.engine.poly_connect("Osc/Saw", "Filter*In", 3) -- connects Osc1/Saw to Filter1*In, Osc2/Saw to Filter2*In and Osc3/Saw to Filter3*In
```

### Utility Functions

``` lua
R.util.split_ref("Osc.Frequency") -- returns {"Osc", "Frequency"}
R.util.poly_expand("Osc", 3) -- returns "Osc1 Osc2 Osc3"
```

## Considerations

- Modules can be connected to feedback but a delay of one processing buffer (64 samples) is introduced. There is no single-sample feedback.
- Shooting a lot of commands to too fast R may cause commands to be delayed. Setting parameter values using `macroset` instead of `set`might help.

## Extending R

Modules are written by way of subclassing the `RModule` class. A subclass supplies a unique module type name (by overriding `*shortName`), an array of specs for each module parameter (`*params`) and a SynthDef Ugen Graph function (`*ugenGraphFunc`) whose function arguments prefixed with `param_`, `in_` and `out_` are treated as parameter controls and input and output busses. The R engine will introspect the ugenGraphFunc and together with the parameter specs provide scaffolding necessary to supply parameter values and interconnect modules.

Note: If a dictionary is supplied for a parameter in the `*params` array, its `Spec` key value will be used as spec and its `LagTime` value will be used as fixed lag rate for the parameter.
Annotated example:

``` supercollider
RTestModule : RModule { // subclassing RModule makes this a module

	*shortName { ^'Test' } // module type used in engine new command

	*params { // description of the module parameters
		^[
			'Frequency' -> \widefreq.asSpec, // first parameter
			'FrequencyModulation' -> (
				Spec: \unipolar.asSpec, // second parameter
				LagTime: 0.05 // 50 ms lag
			)
		]
	}

	*ugenGraphFunc { // regular SynthDef ugenGraphFunc function describing DSP
		^{
			|
				in_FM, // will reference a bus to be used for audio input
				out_Out, // will reference a bus to be used for audio output
				param_Frequency, // refer to first parameter's value...
				param_FrequencyModulation // ... and second parameter's value
			|

			var sig_FM = In.ar(in_FM);
			var sig = SinOsc.ar(param_Frequency + (1000 * sig_FM * param_FrequencyModulation)); // linear FM
			Out.ar(out_Out, sig);
		}
	}

}
```

### Updating the R Lua module

To be usable with functions in the R Lua module `R.engine` table module parameter metadata has to be included in the `R.specs` table. `R.specs` can be generated in SuperCollider from RModule metadata using the `Rrrr.generateLuaSpecs` method.

Module documentation stubs may be generated in SuperCollider using the `Engine_R.generateModulesDocSection` method.

### Gotchas

If one of the parameters of a module has a `ControlSpec` not compatible with Lag (ie. the standard `db` `ControlSpec`) lag time should not be used for any of the parameters. This is a known SuperCollider issue. (TODO: describe workaround)

## Status

- Beta-stage. Engine commands are fixed. A few modules are not tested. Expect changes to module parameter/input/output ranges.

