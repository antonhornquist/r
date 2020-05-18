(
var include_relative = { |relative_path|
	var path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ relative_path).standardizePath;
	this.executeFile(path);
};

var voice = include_relative.value("lib/voice.scd");
~voice_new = voice[\voice_new];
)

~voice_allocator = ~voice_new.value(3);

~slot1 = ~voice_allocator.get__
~slot1.on_release__ = { |slot| "slot % ".format(slot.id__).debug(\released); };

~slot2 = ~voice_allocator.get__
~slot2.on_release__ = { |slot| "slot % ".format(slot.id__).debug(\released); };

~slot3 = ~voice_allocator.get__
~slot3.on_release__ = { |slot| "slot % ".format(slot.id__).debug(\released); };

~slot4 = ~voice_allocator.get__
~slot4.on_release__ = { |slot| "slot % ".format(slot.id__).debug(\released); };

~slot5 = ~voice_allocator.get__
~slot5.on_release__ = { |slot| "slot % ".format(slot.id__).debug(\released); };

~voice_allocator.release__(~slot3);

1