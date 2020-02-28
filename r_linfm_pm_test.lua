engine.name = 'R'

local R = require 'r/lib/r'
local Formatters = require 'formatters'

local ControlSpec = require 'controlspec'

function init()
  engine.new("Osc1", "SineOsc")
  engine.new("Osc2", "SineOsc")
  engine.new("FreqGate", "FreqGate")
  engine.new("SoundOut", "SoundOut")
  engine.new("FMamp", "Amp")
  engine.new("Amp", "Amp")

  engine.connect("FreqGate/Frequency", "Osc1/FM")
  engine.connect("FreqGate/Frequency", "Osc2/FM")
  engine.connect("FreqGate/Gate", "Amp/Lin")
  engine.connect("Osc2/Out", "FMamp/In")
  engine.connect("FMamp/Out", "Osc1/FM")
  engine.connect("Osc2/Out", "Osc1/PM")
  engine.connect("Osc2/Out", "Osc1/LinFM")
  engine.connect("Osc1/Out", "Amp/In")
  engine.connect("Osc1/Out", "Amp/In")
  engine.connect("Amp/Out", "SoundOut/Left")
  engine.connect("Amp/Out", "SoundOut/Right")
  
  -- engine.connect("Osc1/Out", "SoundOut/Left")
  -- engine.connect("Osc1/Out", "SoundOut/Right")
  
  engine.set("Osc1.FM", 1)
  engine.set("Osc2.FM", 1)
  
  params:add {
    type="control",
    id="osc_range",
    name="Osc1.Range",
    controlspec=R.specs.SineOsc.Range,
    action=function(value) engine.set("Osc1.Range", value) end
  }

  params:add {
    type="control",
    id="osc_tune",
    name="Osc1.Tune",
    controlspec=R.specs.SineOsc.Tune,
    action=function(value) engine.set("Osc1.Tune", value) end
  }
  
  params:add {
    type="control",
    id="osc_fm",
    name="Osc1.FM",
    controlspec=R.specs.SineOsc.FM,
    action=function(value) engine.set("FMamp.Level", value) end
  }

  params:add {
    type="control",
    id="osc_linfm",
    name="Osc1.LinFM",
    controlspec=R.specs.SineOsc.LinFM,
    action=function(value) engine.set("Osc1.LinFM", value) end
  }
  
  params:add {
    type="control",
    id="osc_pm",
    name="Osc1.PM",
    controlspec=R.specs.SineOsc.PM, --ControlSpec.new(0, 2, 'lin', 0, 0, ""),
    action=function(value) engine.set("Osc1.PM", value) end
  }
  
  params:add {
    type="control",
    id="osc_range",
    name="Osc2.Range",
    controlspec=R.specs.SineOsc.Range,
    action=function(value) engine.set("Osc2.Range", value) end
  }
  -- params:bang()
end

m = midi.connect()
m.event = function(data)
  local d = midi.to_msg(data)
  if d.type == "note_on" then
    engine.set("FreqGate.Frequency", (440 / 32) * (2 ^ ((d.note - 9) / 12)))
    engine.set("FreqGate.Gate", 1)
  elseif d.type == "note_off" then
    engine.set("FreqGate.Gate", 0)
  end
end

function enc(n, delta)
  if n == 1 then
    mix:delta("output", delta)
  end
end