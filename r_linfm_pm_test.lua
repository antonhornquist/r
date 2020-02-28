engine.name = 'R'

local R = require 'r/lib/r'
local Formatters = require 'formatters'

local ControlSpec = require 'controlspec'

function init()
  engine.new("Osc1", "SineOsc")
  engine.new("Osc2", "SineOsc")
  engine.new("SoundOut", "SoundOut")

engine.connect("Osc2/Out", "Osc1/FM")
  engine.connect("Osc2/Out", "Osc1/PM")
  engine.connect("Osc2/Out", "Osc1/LinFM")
  engine.connect("Osc1/Out", "SoundOut/Left")
  engine.connect("Osc1/Out", "SoundOut/Right")
  
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
    action=function(value) engine.set("Osc1.FM", value) end
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
    controlspec=R.specs.SineOsc.PM,
    action=function(value) engine.set("Osc1.PM", value) end
  }
  
  params:add {
    type="control",
    id="osc_range",
    name="Osc2.Range",
    controlspec=R.specs.SineOsc.Range,
    action=function(value) engine.set("Osc2.Range", value) end
  }

  params:add {
    type="control",
    id="osc_tune",
    name="Osc2.Tune",
    controlspec=R.specs.SineOsc.Tune,
    action=function(value) engine.set("Osc2.Tune", value) end
  }

  params:bang()
end

function enc(n, delta)
  if n == 1 then
    mix:delta("output", delta)
  end
end