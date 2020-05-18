(
// ported from lua code by @ngwese

// (voice) Slot class
var slot_new = { |pool, id|
	var obj = ();
	obj.pool__ = pool;
	obj.id__ = id;
	obj.active__ = false;
	obj.on_release__ = nil;
	obj.on_steal__ = nil;
	obj.release__ = { |self|
		self[\pool__].release__(self);
	};
	obj
};

// LRU allocation class
var lru_new = { |polyphony, slots|
	var obj = ();
	obj.slots_ = slots;
	obj.count_ = 0;
	slots.do { |slot|
		slot.n_ = 0;
	};
	obj.next__ = { |self|
		var count = self.count_ + 1;
		var next = self.slots_[0];
		var free = nil;

		self.count_ = count;
		self.slots_.do { |slot|
			case
			{ slot.active__.not } {
				if (
					if (free.isNil) {
						true
					} {
						slot.n_ < free.n_
					}
				) {
					free = slot;
				};
			}
			{ slot.n_ < next.n_ } {
				next = slot;
			};
		};
		// choose free voice if possible
		if (free.notNil) {
			next = free;
		};
		next.n_ = count;
		next;
	};
	obj;
};

// Voice class

/// create a new Voice
var voice_new = { |polyphony, mode|
	var obj = ();
	var slots;

	obj.polyphony__ = polyphony;
	obj.mode_ = mode;
	obj.will_steal__ = nil; // event callback
	obj.will_release__ = nil; // event callback
	obj.pairings__ = IdentityDictionary[];

	slots = polyphony.collect { |id|
		slot_new.value(obj, id+1);
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
1.debug;
slot.debug(\voice_get__);
		if (slot.active__) {
			var pairing;
2.debug;

			if (self[\will_steal__].notNil) {
				self[\will_steal__].value(slot);
			};

			// ack; nuke any existing pairings
			self.pairings__.keys.do { |key|
				if (self.pairings__[key] == slot) {
					self.pairings__[key] = nil;
				};

				case
				{ slot[\on_steal__].notNil } {
					slot[\on_steal__].value(slot);
				}
				{ slot[\on_release__].notNil } {
					slot[\on_release__].value(slot);
				}
			};
		};
		slot.active__ = true;
		slot;
	};
	/// return voice slot to pool
	obj.release__ = { |self, slot|
/*
[self, slot].debug(\obj_release_);
*/
'zzz'.debug;
		if (slot.pool__ == self) {
1.debug;
			if (self[\will_release__].notNil) {
2.debug;
				self[\will_release__].value(slot);
			};
			if (self[\on_release__].notNil) {
3.debug;
				self[\on_release__].value(slot);
			};
4.debug;
			slot.active__ = false;
		} {
5.debug;
			postln("voice slot: " ++ slot.asString ++ " does not belong to pool: " ++ self.asString);
6.debug;
		}
	};
	obj;
};

var module = IdentityDictionary[
	\voice_new -> voice_new
];

module
)
