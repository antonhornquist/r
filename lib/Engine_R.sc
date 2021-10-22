Engine_R : CroneEngine {
	var <rrrr;

	var numPolls = 10;

	var <pollConfigs;
	var defaultPollRate = 10; // poll updates per second

	var init, free, newCommand, connectCommand, disconnectCommand, deleteCommand, setCommand, bulksetCommand, newmacroCommand, deletemacroCommand, macrosetCommand, readsampleCommand, tapoutputCommand, tapclearCommand, getTapBus, getVisualBus;

	var polloutputCommand, pollvisualCommand, pollclearCommand;

	*new { |context, callback| ^super.new(context, callback) }

	getScdBasedEngine {
		var scdFilePath = (PathName(this.class.filenameSymbol.asString).pathOnly +/+ "r.scd").standardizePath;

		var postPollIndexNotWithinBoundsError = { |pollIndex|
			"poll index not within bounds: pollIndex % referred, only % polls available".format(pollIndex, numPolls).error;
		};

		var ifPollIndexWithinBoundsDo = { |oneBasedIndex, func|
			if ((1 <= oneBasedIndex) and: (oneBasedIndex <= numPolls)) {
				func.value;
			} {
				postPollIndexNotWithinBoundsError.value(oneBasedIndex);
			};
		};

		polloutputCommand = { |rrrr, oneBasedIndex, outputRef|
			ifPollIndexWithinBoundsDo.value(oneBasedIndex) {
				var zeroBasedIndex = oneBasedIndex - 1; // lua based indexing is used in engine interface
				var pollConfig = pollConfigs[zeroBasedIndex];
				if (pollConfig[\type].notNil) {
					pollclearCommand.value(oneBasedIndex);
				};
				tapoutputCommand.value(rrrr, zeroBasedIndex, outputRef);
				pollConfig[\type] = \out;
				pollConfig[\outputRef] = outputRef;
				pollConfig[\bus] = getTapBus.value(rrrr, zeroBasedIndex);
			};
		};

		pollvisualCommand = { |rrrr, oneBasedIndex, visual|
			ifPollIndexWithinBoundsDo.value(oneBasedIndex) {
				var zeroBasedIndex = oneBasedIndex - 1; // lua based indexing is used in engine interface
				var pollConfig = pollConfigs[zeroBasedIndex];
				if (pollConfig[\type].notNil) {
					pollclearCommand.value(oneBasedIndex);
				};
				pollConfig[\type] = \visual;
				pollConfig[\visual] = visual;
				pollConfig[\bus] = getVisualBus.value(rrrr, visual);
			};
		};

		pollclearCommand = { |rrrr, oneBasedIndex|
			ifPollIndexWithinBoundsDo.value(oneBasedIndex) {
				var zeroBasedIndex = oneBasedIndex - 1; // lua based indexing is used in engine interface
				var pollConfig = pollConfigs[zeroBasedIndex];
				if (pollConfig[\type] == \out) {
					tapclearCommand.value(rrrr, zeroBasedIndex);
				};
				pollConfig[\type] = nil;
				pollConfig[\outputRef] = nil;
				pollConfig[\visual] = nil;
				pollConfig[\bus] = nil;
			};
		};

		^thisProcess.interpreter.executeFile(scdFilePath);
	}

	alloc {
		var scdAPI = this.getScdBasedEngine;
		init = scdAPI[\init];
		free = scdAPI[\free];
		newCommand = scdAPI[\newCommand];
		connectCommand = scdAPI[\connectCommand];
		disconnectCommand = scdAPI[\disconnectCommand];
		deleteCommand = scdAPI[\deleteCommand];
		setCommand = scdAPI[\setCommand];
		bulksetCommand = scdAPI[\bulksetCommand];
		newmacroCommand = scdAPI[\newmacroCommand];
		deletemacroCommand = scdAPI[\deletemacroCommand];
		macrosetCommand = scdAPI[\macrosetCommand];
		readsampleCommand = scdAPI[\readsampleCommand];
		tapoutputCommand = scdAPI[\tapoutputCommand];
		tapclearCommand = scdAPI[\tapclearCommand];
		getTapBus = scdAPI[\getTapBus];
		getVisualBus = scdAPI[\getVisualBus];

		rrrr=init.(
			(
				trace: false,
				group: context.xg,
				inBus: context.in_b,
				outBus: context.out_b,
				numTaps: numPolls
			)
		);

		this.addCommands;
		this.addPolls;
	}

	addCommands {
		this.addCommand('new', "ss") { |msg|
			var moduleRef = msg[1];
			var moduleType = msg[2];
			if (rrrr[\trace]) {
				[SystemClock.seconds, \newCommand, moduleRef, moduleType].debug(\received);
			};
			newCommand.value(rrrr, moduleRef, moduleType);
		};

		this.addCommand('delete', "s") { |msg|
			var moduleRef = msg[1];
			if (rrrr[\trace]) {
				[SystemClock.seconds, \deleteCommand, moduleRef.asString[0..20]].debug(\received);
			};
			deleteCommand.value(rrrr, moduleRef);
		};

		this.addCommand('connect', "ss") { |msg|
			var moduleOutputRef = msg[1];
			var moduleInputRef = msg[2];
			if (rrrr[\trace]) {
				[SystemClock.seconds, \connectCommand, (moduleOutputRef.asString + moduleInputRef.asString)[0..20]].debug(\received);
			};
			connectCommand.value(rrrr, moduleOutputRef, moduleInputRef);
		};

		this.addCommand('disconnect', "ss") { |msg|
			var moduleOutputRef = msg[1];
			var moduleInputRef = msg[2];
			if (rrrr[\trace]) {
				[SystemClock.seconds, \disconnectCommand, (moduleOutputRef.asString + moduleInputRef.asString)[0..20]].debug(\received);
			};
			disconnectCommand.value(rrrr, moduleOutputRef, moduleInputRef);
		};

		this.addCommand('set', "sf") { |msg|
			var moduleParameterRef = msg[1];
			var value = msg[2];
			if (rrrr[\trace]) {
				[SystemClock.seconds, \setCommand, (moduleParameterRef.asString + value.asString)[0..20]].debug(\received);
			};
			setCommand.value(rrrr, moduleParameterRef, value);
		};

		this.addCommand('bulkset', "s") { |msg|
			var bundle = msg[1];
			if (rrrr[\trace]) {
				[SystemClock.seconds, \bulksetCommand, bundle.asString[0..20]].debug(\received);
			};
			bulksetCommand.value(rrrr, bundle);
		};

		this.addCommand('newmacro', "ss") { |msg|
			var name = msg[1];
			var bundle = msg[2];
			if (rrrr[\trace]) {
				[SystemClock.seconds, \newmacroCommand, (name.asString + bundle.asString)[0..20]].debug(\received);
			};
			newmacroCommand.value(rrrr, name, bundle);
		};

		this.addCommand('deletemacro', "s") { |msg|
			var name = msg[1];
			if (rrrr[\trace]) {
				[SystemClock.seconds, \deletemacroCommand, (name.asString)[0..20]].debug(\received);
			};
			deletemacroCommand.value(rrrr, name);
		};

		this.addCommand('macroset', "sf") { |msg|
			var name = msg[1];
			var value = msg[2];
			if (rrrr[\trace]) {
				[SystemClock.seconds, \macrosetCommand, (name.asString + value.asString)[0..20]].debug(\received);
			};
			macrosetCommand.value(rrrr, name, value);
		};

		this.addCommand('polloutput', "is") { |msg|
			var oneBasedIndex = msg[1];
			var moduleOutputRef = msg[2];
			if (rrrr[\trace]) {
				[SystemClock.seconds, \polloutputCommand, (oneBasedIndex.asString + moduleOutputRef.asString)[0..20]].debug(\received);
			};
			polloutputCommand.value(rrrr, oneBasedIndex, moduleOutputRef);
		};

		this.addCommand('pollvisual', "is") { |msg|
			var oneBasedIndex = msg[1];
			var moduleVisualRef = msg[2];
			if (rrrr[\trace]) {
				[SystemClock.seconds, \pollvisualCommand, (oneBasedIndex.asString + moduleVisualRef.asString)[0..20]].debug(\received);
			};
			pollvisualCommand.value(rrrr, oneBasedIndex, moduleVisualRef);
		};

		this.addCommand('pollclear', "i") { |msg|
			var oneBasedIndex = msg[1];
			if (rrrr[\trace]) {
				[SystemClock.seconds, \pollclearCommand, (oneBasedIndex.asString)[0..20]].debug(\received);
			};
			pollclearCommand.value(rrrr, oneBasedIndex);
		};

		this.addCommand('readsample', "ss") { |msg|
			var moduleSampleSlotRef = msg[1];
			var path = msg[2];
			if (rrrr[\trace]) {
				[SystemClock.seconds, \readsampleCommand, (moduleSampleSlotRef.asString + path.asString)[0..20]].debug(\received);
			};
			readsampleCommand.value(rrrr, moduleSampleSlotRef, path.asString);
		};

		this.addCommand('trace', "i") { |msg|
			rrrr[\trace] = msg[1].asBoolean;
		};
	}

	polloutputCommand { |zeroBasedIndex, outputRef|
		var pollConfig = pollConfigs[zeroBasedIndex];
		if (pollConfig[\type].notNil) {
			this.pollclearCommand(zeroBasedIndex);
		};
		rrrr.tapoutletCommand(zeroBasedIndex, outputRef);
		pollConfig[\type] = \out;
		pollConfig[\outputRef] = outputRef;
		pollConfig[\bus] = rrrr.getTapBus(zeroBasedIndex);
	}

	pollvisualCommand { |zeroBasedIndex, visual|
		var pollConfig = pollConfigs[zeroBasedIndex];
		if (pollConfig[\type].notNil) {
			this.pollclearCommand(zeroBasedIndex);
		};
		pollConfig[\type] = \visual;
		pollConfig[\visual] = visual;
		pollConfig[\bus] = rrrr.getVisualBus(visual);
	}

	pollclearCommand { |zeroBasedIndex|
		var pollConfig = pollConfigs[zeroBasedIndex];
		if (pollConfig[\type] == \out) {
			rrrr.tapclearCommand(zeroBasedIndex);
		};
		pollConfig[\type] = nil;
		pollConfig[\outputRef] = nil;
		pollConfig[\visual] = nil;
		pollConfig[\bus] = nil;
	}

	addPolls {
		pollConfigs = () ! numPolls;

		numPolls do: { |pollIndex|
			var poll = this.addPoll(("poll" ++ (pollIndex+1)).asSymbol, {
				var pollConfig = pollConfigs[pollIndex];
				var bus, value;

				bus = pollConfig[\bus];
				if (bus.notNil) {
					value = bus.getSynchronous; // note: getSynchronous does not work with remote servers
				};

				value;
			});
			poll.setTime(1/defaultPollRate);
			pollConfigs[pollIndex][\poll] = poll;
		};
	}

	free {
		free.(rrrr);
	}
}
