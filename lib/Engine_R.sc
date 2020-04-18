Engine_R : CroneEngine {
	var <rrrr;

	var useScdBasedR = false;
	var numPolls = 10;

	var <pollConfigs;

	var init, free, newCommand, connectCommand, disconnectCommand, deleteCommand, setCommand, bulksetCommand, newmacroCommand, deletemacroCommand, macrosetCommand, readsampleCommand, tapoutputCommand, tapclearCommand, getTapBus, getVisualBus;

	var polloutputCommand, pollvisualCommand, pollclearCommand;

	*new { |context, callback| ^super.new(context, callback) }

	spawnScdBasedRrrr {
		var scdFilePath = (PathName(this.class.filenameSymbol.asString).pathOnly +/+ ".." +/+ "r.scd").standardizePath;

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
		if (useScdBasedR) {
			var rScdAPI = this.spawnScdBasedRrrr;
			init = rScdAPI[\init];
			free = rScdAPI[\free];
			newCommand = rScdAPI[\newCommand];
			connectCommand = rScdAPI[\connectCommand];
			disconnectCommand = rScdAPI[\disconnectCommand];
			deleteCommand = rScdAPI[\deleteCommand];
			setCommand = rScdAPI[\setCommand];
			bulksetCommand = rScdAPI[\bulksetCommand];
			newmacroCommand = rScdAPI[\newmacroCommand];
			deletemacroCommand = rScdAPI[\deletemacroCommand];
			macrosetCommand = rScdAPI[\macrosetCommand];
			readsampleCommand = rScdAPI[\readsampleCommand];
			tapoutputCommand = rScdAPI[\tapoutputCommand];
			tapclearCommand = rScdAPI[\tapclearCommand];
			getTapBus = rScdAPI[\getTapBus];
			getVisualBus = rScdAPI[\getVisualBus];

			rrrr=init.(
				(
					trace: true,
					group: context.xg,
					inBus: context.in_b,
					outBus: context.out_b,
					numTaps: numPolls
				)
			);
		} {
			rrrr = Rrrr.new(
				(
					server: context.server,
					group: context.xg,
					inBus: context.in_b,
					outBus: context.out_b,
					numTaps: 10
				)
			);
		};

		this.addCommands;
		this.addPolls;
	}

	addCommands {
		if (useScdBasedR) {
			this.addCommand('new', "ss") { |msg|
				var moduleRef = msg[1];
				var moduleType = msg[2];
				if (rrrr[\trace]) {
					[SystemClock.seconds, \newCommand, moduleRef, moduleType].debug(\received);
				};
				newCommand.value(rrrr, moduleRef, moduleType);
			};
		} {
			this.addCommand('new', "ss") { |msg|
				if (rrrr.trace) {
					[SystemClock.seconds, \newCommand, msg[1], msg[2]].debug(\received);
				};
				rrrr.newCommand(msg[1], msg[2]);
			};
		};

		if (useScdBasedR) {
			this.addCommand('delete', "s") { |msg|
				var moduleRef = msg[1];
				if (rrrr[\trace]) {
					[SystemClock.seconds, \deleteCommand, moduleRef.asString[0..20]].debug(\received);
				};
				deleteCommand.value(rrrr, moduleRef);
			};
		} {
			this.addCommand('delete', "s") { |msg|
				if (rrrr.trace) {
					[SystemClock.seconds, \deleteCommand, msg[1].asString[0..20]].debug(\received);
				};
				rrrr.deleteCommand(msg[1]);
			};
		};

		if (useScdBasedR) {
			this.addCommand('connect', "ss") { |msg|
				var moduleOutputRef = msg[1];
				var moduleInputRef = msg[2];
				if (rrrr[\trace]) {
					[SystemClock.seconds, \connectCommand, (moduleOutputRef.asString + moduleInputRef.asString)[0..20]].debug(\received);
				};
				connectCommand.value(rrrr, moduleOutputRef, moduleInputRef);
			};
		} {
			this.addCommand('connect', "ss") { |msg|
				if (rrrr.trace) {
					[SystemClock.seconds, \connectCommand, (msg[1].asString + msg[2].asString)[0..20]].debug(\received);
				};
				rrrr.connectCommand(msg[1], msg[2]);
			};
		};

		if (useScdBasedR) {
			this.addCommand('disconnect', "ss") { |msg|
				var moduleOutputRef = msg[1];
				var moduleInputRef = msg[2];
				if (rrrr[\trace]) {
					[SystemClock.seconds, \disconnectCommand, (moduleOutputRef.asString + moduleInputRef.asString)[0..20]].debug(\received);
				};
				disconnectCommand.value(rrrr, moduleOutputRef, moduleInputRef);
			};
		} {
			this.addCommand('disconnect', "ss") { |msg|
				if (rrrr.trace) {
					[SystemClock.seconds, \disconnectCommand, (msg[1].asString + msg[2].asString)[0..20]].debug(\received);
				};
				rrrr.disconnectCommand(msg[1], msg[2]);
			};
		};

		if (useScdBasedR) {
			this.addCommand('set', "sf") { |msg|
				var moduleParameterRef = msg[1];
				var value = msg[2];
				if (rrrr[\trace]) {
					[SystemClock.seconds, \setCommand, (moduleParameterRef.asString + value.asString)[0..20]].debug(\received);
				};
				setCommand.value(rrrr, moduleParameterRef, value);
			};
		} {
			this.addCommand('set', "sf") { |msg|
				if (rrrr.trace) {
					[SystemClock.seconds, \setCommand, (msg[1].asString + msg[2].asString)[0..20]].debug(\received);
				};
				rrrr.setCommand(msg[1], msg[2]);
			};
		};

		if (useScdBasedR) {
			this.addCommand('bulkset', "s") { |msg|
				var bundle = msg[1];
				if (rrrr[\trace]) {
					[SystemClock.seconds, \bulksetCommand, bundle.asString[0..20]].debug(\received);
				};
				bulksetCommand.value(rrrr, bundle);
			};
		} {
			this.addCommand('bulkset', "s") { |msg|
				if (rrrr.trace) {
					[SystemClock.seconds, \bulksetCommand, msg[1].asString[0..20]].debug(\received);
				};
				rrrr.bulksetCommand(msg[1]);
			};
		};

		if (useScdBasedR) {
			this.addCommand('newmacro', "ss") { |msg|
				var name = msg[1];
				var bundle = msg[2];
				if (rrrr[\trace]) {
					[SystemClock.seconds, \newmacroCommand, (name.asString + bundle.asString)[0..20]].debug(\received);
				};
				newmacroCommand.value(rrrr, name, bundle);
			};
		} {
			this.addCommand('newmacro', "ss") { |msg|
				if (rrrr.trace) {
					[SystemClock.seconds, \newmacroCommand, (msg[1].asString + msg[2].asString)[0..20]].debug(\received);
				};
				rrrr.newmacroCommand(msg[1], msg[2]);
			};
		};

		if (useScdBasedR) {
			this.addCommand('deletemacro', "s") { |msg|
				var name = msg[1];
				if (rrrr[\trace]) {
					[SystemClock.seconds, \deletemacroCommand, (name.asString)[0..20]].debug(\received);
				};
				deletemacroCommand.value(rrrr, name);
			};
		} {
			this.addCommand('deletemacro', "s") { |msg|
				if (rrrr.trace) {
					[SystemClock.seconds, \deletemacroCommand, (msg[1].asString)[0..20]].debug(\received);
				};
				rrrr.deletemacroCommand(msg[1]);
			};
		};

		if (useScdBasedR) {
			this.addCommand('macroset', "sf") { |msg|
				var name = msg[1];
				var value = msg[2];
				if (rrrr[\trace]) {
					[SystemClock.seconds, \macrosetCommand, (name.asString + value.asString)[0..20]].debug(\received);
				};
				macrosetCommand.value(rrrr, name, value);
			};
		} {
			this.addCommand('macroset', "sf") { |msg|
				if (rrrr.trace) {
					[SystemClock.seconds, \macrosetCommand, (msg[1].asString + msg[2].asString)[0..20]].debug(\received);
				};
				rrrr.macrosetCommand(msg[1], msg[2]);
			};
		};

		if (useScdBasedR) {
			this.addCommand('polloutput', "is") { |msg|
				var oneBasedIndex = msg[1];
				var moduleOutputRef = msg[2];
				if (rrrr[\trace]) {
					[SystemClock.seconds, \polloutputCommand, (oneBasedIndex.asString + moduleOutputRef.asString)[0..20]].debug(\received);
				};
				polloutputCommand.value(rrrr, oneBasedIndex, moduleOutputRef);
			};
		} {
			this.addCommand('polloutput', "is") { |msg|
				var oneBasedIndex = msg[1];
				var outputRef = msg[2];
				if (rrrr.trace) {
					[SystemClock.seconds, \polloutputCommand, (oneBasedIndex.asString + outputRef.asString)[0..20]].debug(\received);
				};
				this.polloutputCommand(oneBasedIndex-1, outputRef);
			};
		};

		if (useScdBasedR) {
			this.addCommand('pollvisual', "is") { |msg|
				var oneBasedIndex = msg[1];
				var moduleVisualRef = msg[2];
				if (rrrr[\trace]) {
					[SystemClock.seconds, \pollvisualCommand, (oneBasedIndex.asString + moduleVisualRef.asString)[0..20]].debug(\received);
				};
				pollvisualCommand.value(rrrr, oneBasedIndex, moduleVisualRef);
			};
		} {
			this.addCommand('pollvisual', "is") { |msg|
				var oneBasedIndex = msg[1];
				var visualRef = msg[2];
				if (rrrr.trace) {
					[SystemClock.seconds, \pollvisualCommand, (oneBasedIndex.asString + visualRef.asString)[0..20]].debug(\received);
				};
				this.pollvisualCommand(oneBasedIndex-1, visualRef);
			};
		};

		if (useScdBasedR) {
			this.addCommand('pollclear', "i") { |msg|
				var oneBasedIndex = msg[1];
				if (rrrr[\trace]) {
					[SystemClock.seconds, \pollclearCommand, (oneBasedIndex.asString)[0..20]].debug(\received);
				};
				pollclearCommand.value(rrrr, oneBasedIndex);
			};
		} {
			this.addCommand('pollclear', "i") { |msg|
				var oneBasedIndex = msg[1];
				if (rrrr.trace) {
					[SystemClock.seconds, \pollclearCommand, (oneBasedIndex.asString)[0..20]].debug(\received);
				};
				this.pollclearCommand(oneBasedIndex-1);
			};
		};

		if (useScdBasedR) {
			this.addCommand('readsample', "ss") { |msg|
				var moduleSampleSlotRef = msg[1];
				var path = msg[2];
				if (rrrr[\trace]) {
					[SystemClock.seconds, \readsampleCommand, (moduleSampleSlotRef.asString + path.asString)[0..20]].debug(\received);
				};
				readsampleCommand.value(rrrr, moduleSampleSlotRef, path.asString);
			};
		} {
			this.addCommand('readsample', "ss") { |msg|
				var sampleSlot = msg[1];
				var path = msg[2];
				if (rrrr.trace) {
					[SystemClock.seconds, \readsampleCommand, (sampleSlot.asString + path.asString)[0..20]].debug(\received);
				};
				if (useScdBasedR) {
					readsampleCommand.(rrrr, sampleSlot, path.asString);
				} {
					rrrr.readsampleCommand(sampleSlot, path.asString);
				}
			};
		};

		if (useScdBasedR) {
			this.addCommand('trace', "i") { |msg|
				rrrr[\trace] = msg[1].asBoolean;
			};
		} {
			this.addCommand('trace', "i") { |msg|
				rrrr.trace = msg[1].asBoolean;
			};
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
		};
	}

	free {
		if (useScdBasedR) {
			free.(rrrr);
		} {
			rrrr.free;
		};
	}

	*generateLuaSpecs {
		^"local specs = {}\n" ++
		"\n" ++
		Rrrr.allRModuleClasses.collect { |rModuleClass|
			rModuleClass.generateLuaSpecs
		}.join("\n")
	}
}

+ RModule {
	*generateLuaSpecs {
		^"specs['"++this.shortName.asString++"'] = {\n"++
			if (this.params.isNil) {
				""
			} {
				this.spec[\parameters].collect { |param| // TODO: report error when controlSpec is not found / or rely on .asSpec
					var controlSpec = this.paramControlSpecs[("param_"++param.asString).asSymbol]; // TODO: throw error when nothing found -- will happen when *params does not comply with param_Args in ugenGraphFunc
					"\t" ++ param.asString ++ " = " ++ if (controlSpec.class == Symbol) {
						"\\" ++ controlSpec.asString
					} {
						controlSpec.asSpecifier !? { |specifier| "ControlSpec."++specifier.asString.toUpper } ? ("ControlSpec.new("++[
							switch (controlSpec.minval) { -inf } { "-math.huge" } { inf } { "math.huge" } ? controlSpec.minval,
							switch (controlSpec.maxval) { -inf } { "-math.huge" } { inf } { "math.huge" } ? controlSpec.maxval,
							controlSpec.warp.asSpecifier.asString.quote,
							controlSpec.step,
							switch (controlSpec.default) { -inf } { "-math.huge" } { inf } { "math.huge" } ? controlSpec.default,
							controlSpec.units.quote
						].join(", ")++")")
					}
				}.join(",\n") ++ "\n"
			} ++
		"}" ++ "\n";
	}
}
