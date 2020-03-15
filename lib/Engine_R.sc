Engine_R : CroneEngine {
	var <rrrr;

	var numPolls = 10;

	var <pollConfigs;

	*new { |context, callback| ^super.new(context, callback) }

	alloc {
		rrrr = Rrrr.new(
			(
				server: context.server,
				group: context.xg,
				inBus: context.in_b,
				outBus: context.out_b,
				numTaps: 10
			)
		);

		this.addCommands;
		this.addPolls;
	}

	addCommands {
		this.addCommand('new', "ss") { |msg|
			if (rrrr.trace) {
				[SystemClock.seconds, \newCommand, msg[1], msg[2]].debug(\received);
			};
			rrrr.newCommand(msg[1], msg[2]);
		};

		this.addCommand('delete', "s") { |msg|
			if (rrrr.trace) {
				[SystemClock.seconds, \deleteCommand, msg[1].asString[0..20]].debug(\received);
			};
			rrrr.deleteCommand(msg[1]);
		};

		this.addCommand('connect', "ss") { |msg|
			if (rrrr.trace) {
				[SystemClock.seconds, \connectCommand, (msg[1].asString + msg[2].asString)[0..20]].debug(\received);
			};
			rrrr.connectCommand(msg[1], msg[2]);
		};

		this.addCommand('disconnect', "ss") { |msg|
			if (rrrr.trace) {
				[SystemClock.seconds, \disconnectCommand, (msg[1].asString + msg[2].asString)[0..20]].debug(\received);
			};
			rrrr.disconnectCommand(msg[1], msg[2]);
		};

		this.addCommand('set', "sf") { |msg|
			if (rrrr.trace) {
				[SystemClock.seconds, \setCommand, (msg[1].asString + msg[2].asString)[0..20]].debug(\received);
			};
			rrrr.setCommand(msg[1], msg[2]);
		};

		this.addCommand('bulkset', "s") { |msg|
			if (rrrr.trace) {
				[SystemClock.seconds, \bulksetCommand, msg[1].asString[0..20]].debug(\received);
			};
			rrrr.bulksetCommand(msg[1]);
		};

		this.addCommand('newmacro', "ss") { |msg|
			if (rrrr.trace) {
				[SystemClock.seconds, \newmacroCommand, (msg[1].asString + msg[2].asString)[0..20]].debug(\received);
			};
			rrrr.newmacroCommand(msg[1], msg[2]);
		};

		this.addCommand('deletemacro', "s") { |msg|
			if (rrrr.trace) {
				[SystemClock.seconds, \deletemacroCommand, (msg[1].asString)[0..20]].debug(\received);
			};
			rrrr.deletemacroCommand(msg[1]);
		};

		this.addCommand('macroset', "sf") { |msg|
			if (rrrr.trace) {
				[SystemClock.seconds, \macrosetCommand, (msg[1].asString + msg[2].asString)[0..20]].debug(\received);
			};
			rrrr.macrosetCommand(msg[1], msg[2]);
		};

		this.addCommand('polloutput', "is") { |msg|
			var index = msg[1];
			var outputRef = msg[2];
			if (rrrr.trace) {
				[SystemClock.seconds, \polloutCommand, (index.asString + outputRef.asString)[0..20]].debug(\received);
			};
			this.polloutCommand(index-1, outputRef);
		};

		this.addCommand('pollvisual', "is") { |msg| // TODO: rename visual to value, pollvisual to pollvalue
			var index = msg[1];
			var visualRef = msg[2];
			if (rrrr.trace) {
				[SystemClock.seconds, \pollvisualCommand, (index.asString + visualRef.asString)[0..20]].debug(\received);
			};
			this.pollvisualCommand(index-1, visualRef);
		};

		this.addCommand('pollclear', "i") { |msg|
			var index = msg[1];
			if (rrrr.trace) {
				[SystemClock.seconds, \pollclearCommand, (index.asString)[0..20]].debug(\received);
			};
			this.pollclearCommand(index);
		};

		this.addCommand('readsample', "ss") { |msg|
			var sampleSlot = msg[1];
			var path = msg[2];
			if (rrrr.trace) {
				[SystemClock.seconds, \readsampleCommand, (sampleSlot.asString + path.asString)[0..20]].debug(\received);
			};
			rrrr.readsampleCommand(sampleSlot, path.asString);
		};

		this.addCommand('trace', "i") { |msg|
			rrrr.trace = msg[1].asBoolean;
		};
	}

	polloutCommand { |index, outputRef|
		var pollConfig = pollConfigs[index];
		if (pollConfig[\type].notNil) {
			this.pollclearCommand(index);
		};
		rrrr.tapoutletCommand(index, outputRef);
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
		pollConfig[\bus] = rrrr.getVisualBus(visual);
	}

	pollclearCommand { |index|
		var pollConfig = pollConfigs[index];
		if (pollConfig[\type] == \out) {
			rrrr.tapclearCommand(index);
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
		rrrr.free;
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
