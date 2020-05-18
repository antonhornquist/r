(
// ported from lua code by @ngwese

// (voice) Slot class
var slot_new = { |pool, id|
	var obj = ();
[pool, id].debug(\slot_new);
	obj.pool__ = pool;
	obj.id__ = id;
	obj.active__ = false;
	obj.on_release__ = nil;
	obj.on_steal__ = nil;
	obj.release__ = { |self|
'self'.debug(\slot_release);
		self.pool__.release__(self);
	};
	obj
};

// LRU allocation class
var lru_new = { |polyphony, slots|
	var obj = ();
[polyphony, slots].debug(\lru_new);
	obj.slots__ = slots;
	obj.count__ = 0;
	slots.do { |slot|
		slot.n__ = 0; // yuck: add field to slot
	};
	obj.next__ = { |self|
		var count = self.count__ + 1;
		var next = self.slots__[0];
		var free = nil;
'self'.debug(\lru_next);

		self.count__ = count;

		self.slots__.do { |slot|
			case
			{ slot.active__.not } {
				if (
					if (free.isNil) {
						true
					} {
						slot.n__ < free.n__
					}
				) {
					free = slot;
				};
			}
			{ slot.n__ < next.n__ } {
				next = slot;
			};
		};

		// choose free voice if possible
		if (free.notNil) {
			next = free;
		};
		next.n__ = count;
		next;
	};
	obj;
};

// Voice class

/// create a new Voice
var voice_new = { |polyphony, mode|
	var obj = ();
	var slots;
[polyphony, mode].debug(\voice_new);

	obj.polyphony__ = polyphony;
	obj.mode__ = mode;
	obj.will_steal__ = nil; // event callback
	obj.will_release__ = nil; // event callback
	obj.pairings__ = IdentityDictionary[];

	slots = polyphony.collect { |voicenum|
		slot_new.value(obj, voicenum+1);
	};

	case
	{ mode == \mode_rotate } {
		// TODO obj.style__ = rotate_new.value(polyphony, slots);
		this.notYetImplemented;
	}
	{ mode == \mode_random } {
		// TODO obj.style__ = random_new.value(polyphony, slots);
		this.notYetImplemented;
	}
	{ true } {
		obj.style__ = lru_new.value(polyphony, slots);
	};

	/// get next available voice Slot from pool, stealing an active slot if needed
	obj.get__ = { |self|
		var slot = self.style__.next__();
'slot'.debug(\voice_get__);

		if (slot.active__) {
			if (self[\will_steal__].notNil) {
				self[\will_steal__].value(slot);
			};

			// ack; nuke any existing pairings
			self.pairings__.keys.do { |key|
				if (self.pairings__[key] == slot) {
					self.pairings__[key] = nil;
				};
			};

			case
			{ slot[\on_steal__].notNil } {
				slot[\on_steal__].value(slot);
			}
			{ slot[\on_release__].notNil } {
				slot[\on_release__].value(slot);
			};
		};
		slot.active__ = true;
		slot;
	};
	/// return voice slot to pool
	obj.release__ = { |self, slot|
'self, slot'.debug(\voice_release__);
		if (slot[\pool__] === self) {
			if (self[\will_release__].notNil) {
				self[\will_release__].value(slot);
			};
			if (slot[\on_release__].notNil) {
				slot[\on_release__].value(slot);
			};
			slot.active__ = false;
		} {
			postln("voice slot: " ++ slot.id__.asString ++ " does not belong to pool.");
		};
	};
	obj;
};

var module = IdentityDictionary[
	\voice_new -> voice_new
];

module
)
