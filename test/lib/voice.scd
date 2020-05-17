(
// ported from lua code by @ngwese

// (voice) Slot class
var slot_new = { |pool, id|
	var obj = ();
	obj[\pool_] = pool;
	obj.id_ = id;
	obj.active_ = false;
	obj.on_release_ = nil;
	obj.on_steal_ = nil;
	obj.release_ = { |self|
		self[\pool_].release_(self);
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
	obj.next_ = { |self|
		var count = self.count_ + 1;
		var next = self.slots_[0];
		var free = nil;

		self.count_ = count;
		self.slots_.do { |slot|
			case
			{ slot.active_.not } {
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

	obj.polyphony_ = polyphony;
	obj.mode_ = mode;
	obj.will_steal_ = nil; // event callback
	obj.will_release_ = nil; // event callback
	obj.pairings_ = IdentityDictionary[];

	slots = polyphony.collect { |id|
		slot_new.value(obj, id+1);
	};

	case
	{ mode == \mode_rotate } {
		// TODO obj.style_ = rotate_new.value(polyphony, slots);
		this.notYetImplemented;
	}
	{ mode == \mode_random } {
		// TODO obj.style_ = random_new.value(polyphony, slots);
		this.notYetImplemented;
	}
	{ true } {
		obj.style_ = lru_new.value(polyphony, slots);
	};

	/// get next available voice Slot from pool, stealing an active slot if needed
	obj.get_ = { |self|
		var slot = self.style_.next_();
1.debug;
		if (slot.active_) {
			var pairing;
2.debug;

			if (self[\will_steal_].notNil) {
				self[\will_steal_].value(slot);
			};

			// ack; nuke any existing pairings
			self.pairings_.keys.do { |key|
				if (self.pairings_[key] == slot) {
					self.pairings_[key] = nil;
				};

				case
				{ slot[\on_steal_].notNil } {
					slot[\on_steal_].value(slot);
				}
				{ slot[\on_release_].notNil } {
					slot[\on_release_].value(slot);
				}
			};
		};
		slot.active_ = true;
		slot;
	};
	/// return voice slot to pool
	obj.release_ = { |self, slot|
[self, slot].debug(\obj_release_);
/*
		if (slot.pool_ == self) {
1.debug;
			if (self[\will_release_].notNil) {
2.debug;
				self[\will_release_].value(slot);
			};
			if (self[\on_release_].notNil) {
3.debug;
				self[\on_release_].value(slot);
			};
4.debug;
			slot.active_ = false;
		} {
5.debug;
			postln("voice slot: " ++ slot.asString ++ " does not belong to pool: " ++ self.asString);
6.debug;
		}
*/
	};
	obj;
};

var module = IdentityDictionary[
	\voice_new -> voice_new
];

module
)
