Engine_R : CroneEngine {
	var <rrrr;

	var scdBasedRrrr = false;
	var numPolls = 10;

	var <pollConfigs;

	var init, free, newCommand, connectCommand, disconnectCommand, deleteCommand, setCommand, bulksetCommand, newmacroCommand, deletemacroCommand, macrosetCommand, readsampleCommand, tapoutputCommand, tapclearCommand, getTapBus, getVisualBus;

	var polloutputCommand, pollvisualCommand, pollclearCommand;

	*new { |context, callback| ^super.new(context, callback) }

	spawnScdBasedRrrr {
		var scdFilePath = PathName(this.class.filenameSymbol.asString).pathOnly +/+ "r.scd";

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

		polloutputCommand = { |rrrr, index, outputRef|
			ifPollIndexWithinBoundsDo.value(index) {
				var zeroBasedIndex = index - 1; // lua based indexing is used in engine interface
				var pollConfig = pollConfigs[zeroBasedIndex];
				if (pollConfig[\type].notNil) {
					pollclearCommand.value(index);
				};
				tapoutputCommand.value(rrrr, zeroBasedIndex, outputRef);
				pollConfig[\type] = \out;
				pollConfig[\outputRef] = outputRef;
				pollConfig[\bus] = getTapBus.value(rrrr, zeroBasedIndex);
			};
		};

		pollvisualCommand = { |rrrr, index, visual|
			ifPollIndexWithinBoundsDo.value(index) {
				var zeroBasedIndex = index - 1; // lua based indexing is used in engine interface
				var pollConfig = pollConfigs[zeroBasedIndex];
				if (pollConfig[\type].notNil) {
					pollclearCommand.value(index);
				};
				pollConfig[\type] = \visual;
				pollConfig[\visual] = visual;
				pollConfig[\bus] = getVisualBus.value(rrrr, visual);
			};
		};

		pollclearCommand = { |rrrr, index|
			ifPollIndexWithinBoundsDo.value(index) {
				var zeroBasedIndex = index - 1; // lua based indexing is used in engine interface
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
		if (scdBasedRrrr) {
			# init, free, newCommand, connectCommand, disconnectCommand, deleteCommand, setCommand, bulksetCommand, newmacroCommand, deletemacroCommand, macrosetCommand, readsampleCommand, tapoutputCommand, tapclearCommand, getTapBus, getVisualBus = this.spawnScdBasedRrrr;

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
		if (scdBasedRrrr) {
			this.addCommand('new', "ss") { |msg| // TODO: align terminology
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

		if (scdBasedRrrr) {
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

		if (scdBasedRrrr) {
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

		if (scdBasedRrrr) {
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

		if (scdBasedRrrr) {
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

		if (scdBasedRrrr) {
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

		if (scdBasedRrrr) {
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

		if (scdBasedRrrr) {
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

		if (scdBasedRrrr) {
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

		if (scdBasedRrrr) {
			this.addCommand('polloutput', "is") { |msg|
				var index = msg[1];
				var moduleOutputRef = msg[2];
				if (rrrr[\trace]) {
					[SystemClock.seconds, \polloutputCommand, (index.asString + moduleOutputRef.asString)[0..20]].debug(\received);
				};
				polloutputCommand.value(rrrr, index, moduleOutputRef);
			};
		} {
			this.addCommand('polloutput', "is") { |msg|
				var index = msg[1];
				var outputRef = msg[2];
				if (rrrr.trace) {
					[SystemClock.seconds, \polloutputCommand, (index.asString + outputRef.asString)[0..20]].debug(\received);
				};
				this.polloutCommand(index-1, outputRef);
			};
		};

		if (scdBasedRrrr) {
			this.addCommand('pollvisual', "is") { |msg| // TODO: rename visual to value, pollvisual to pollvalue?
				var index = msg[1];
				var moduleVisualRef = msg[2];
				if (rrrr[\trace]) {
					[SystemClock.seconds, \pollvisualCommand, (index.asString + moduleVisualRef.asString)[0..20]].debug(\received);
				};
				pollvisualCommand.value(rrrr, index, moduleVisualRef);
			};
		} {
			this.addCommand('pollvisual', "is") { |msg| // TODO: rename visual to value, pollvisual to pollvalue
				var index = msg[1];
				var visualRef = msg[2];
				if (rrrr.trace) {
					[SystemClock.seconds, \pollvisualCommand, (index.asString + visualRef.asString)[0..20]].debug(\received);
				};
				this.pollvisualCommand(index-1, visualRef);
			};
		};

		if (scdBasedRrrr) {
			this.addCommand('pollclear', "i") { |msg|
				var index = msg[1];
				if (rrrr[\trace]) {
					[SystemClock.seconds, \pollclearCommand, (index.asString)[0..20]].debug(\received);
				};
				pollclearCommand.value(rrrr, index);
			};
		} {
			this.addCommand('pollclear', "i") { |msg|
				var index = msg[1];
				if (rrrr.trace) {
					[SystemClock.seconds, \pollclearCommand, (index.asString)[0..20]].debug(\received);
				};
				this.pollclearCommand(index);
			};
		};

		if (scdBasedRrrr) {
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
				if (scdBasedRrrr) {
					readsampleCommand.(rrrr, sampleSlot, path.asString);
				} {
					rrrr.readsampleCommand(sampleSlot, path.asString);
				}
			};
		};

		if (scdBasedRrrr) {
			this.addCommand('trace', "i") { |msg|
				rrrr[\trace] = msg[1].asBoolean;
			};
		} {
			this.addCommand('trace', "i") { |msg|
				rrrr.trace = msg[1].asBoolean;
			};
		};
	}

	polloutputCommand { |index, outputRef|
		var pollConfig = pollConfigs[index];
		if (pollConfig[\type].notNil) {
			this.pollclearCommand(index);
		};
		if (scdBasedRrrr) {
			tapoutputCommand.(rrrr, index, outputRef);
		} {
			rrrr.tapoutletCommand(index, outputRef);
		};
		pollConfig[\type] = \out;
		pollConfig[\outputRef] = outputRef;
		pollConfig[\bus] = rrrr.getTapBus(index);
	}

	pollvisualCommand { |index, visual|
		var pollConfig = pollConfigs[index];
		if (pollConfig[\type].notNil) {
			this.pollclearCommand(index);
		};
		pollConfig[\type] = \visual;
		pollConfig[\visual] = visual;
		if (scdBasedRrrr) {
			pollConfig[\bus] = getVisualBus.(rrrr, visual);
		} {
			pollConfig[\bus] = rrrr.getVisualBus(visual);
		};
	}

	pollclearCommand { |index|
		var pollConfig = pollConfigs[index];
		if (pollConfig[\type] == \out) {
			if (scdBasedRrrr) {
				tapclearCommand.(rrrr, index);
			} {
				rrrr.tapclearCommand(index);
			};
		};
		pollConfig[\type] = nil;
		pollConfig[\outputRef] = nil;
		pollConfig[\visual] = nil;
		pollConfig[\bus] = nil;
	}

	addPolls {
		pollConfigs = () ! numPolls;

		numPolls do: { |pollIndex|
			var poll = this.addPoll(("poll" ++ (pollIndex+1)).asSymbol, { // TODO: 1..numPolls or 0..numPolls? 
				var pollConfig = pollConfigs[pollIndex];
				var bus, value;

				bus = pollConfig[\bus];
				if (bus.notNil) {
					value = bus.getSynchronous; // note: getSynchronous does not work with remote servers
				};

				value;
			});
			poll.setTime(1/30); // 30 FPS
		};
	}

	free {
		if (scdBasedRrrr) {
			free.(rrrr);
		} {
			rrrr.free;
		};
		// TODO: remove polls?
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
