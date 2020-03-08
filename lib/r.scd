(
var version = "2.0";
var defaultNumTaps = 10;

var moduleInputRefDelimiter = $*;
var moduleOutputRefDelimiter = $/;
var moduleParameterRefDelimiter = $.;
var moduleVisualRefDelimiter = $=;
var moduleSampleSlotRefDelimiter = $:;

var init = { |opts|
	var instance = ();
	var moduleDefs, autostartServer, trace, group, inBus, outBus, numTaps;

	# moduleDefs, autostartServer, trace, group, inBus, outBus, numTaps = parseOpts.value(opts ? ());

	"R is initializing... ".postln;

	instance[\trace] = trace;
	instance[\group] = group;
	instance[\inBus] = inBus;
	instance[\outBus] = outBus;
	instance[\numTaps] = numTaps;

	instance[\moduleDefs] = moduleDefs ? [];
	instance[\moduleDefs] = instance[\moduleDefs]++coreModules++stdModules;
	instance[\moduleDefs] = validateAndExpandModuleDefs.value(instance[\moduleDefs]);

	instance[\macros] = ();
	instance[\modules] = [];

	if (Server.default.serverRunning) {
		{
			initServerResources.value(instance);
			"R initialized successfully.".postln;
		}.forkIfNeeded;
	} {
		if (autostartServer) {
			postAutobootingServerInformation.value;
			Server.default.waitForBoot {
				initServerResources.value(instance);
				"R initialized successfully.".postln;
			};
		} {
			"R initialization failed.".postln;
			postServerNotRunningError.value;
		};
	};
	instance;
};

var parseOpts = { |opts|
	[
		opts[\moduleDefs],
		opts[\autostartServer] ? true,
		opts[\trace] ? false,
		opts[\group] ? Server.default.defaultGroup,
		opts[\inBus] ? Server.default.options.numOutputBusChannels,
		opts[\outBus] ? 0,
		opts[\numTaps] ? defaultNumTaps
	]
};

var validateAndExpandModuleDefs = { |moduleDefs|
	moduleDefs.collect { |moduleDef|
		var expandedModuleDef;
		var ins;
		var outs;
		var params;
		var visuals;
		var sampleSlots;

		expandedModuleDef = ();
	
		if (moduleDef[\name].notNil) {
			expandedModuleDef[\name] = moduleDef[\name];
		} {
			Error("Module definition requires a name").throw;
		};

		if (moduleDef[\ugenGraphFunc].notNil) {
			expandedModuleDef[\ugenGraphFunc] = moduleDef[\ugenGraphFunc];
		} {
			Error("Module definition requires an ugenGraphFunc").throw;
		};

		ins = moduleDef[\ins];
		if (ins.notNil) {
			// TODO: validate against ugenGraphFunc
			expandedModuleDef[\ins] = ins.value;
		};

		outs = moduleDef[\outs];
		if (outs.notNil) {
			// TODO: validate against ugenGraphFunc
			expandedModuleDef[\outs] = outs.value;
		};

		params = moduleDef[\params];
		if (params.notNil) {
			// TODO: validate against ugenGraphFunc
			expandedModuleDef[\params] = params.value;
		};

		visuals = moduleDef[\visuals];
		if (visuals.notNil) {
			// TODO: validate against ugenGraphFunc
			expandedModuleDef[\visuals] = visuals.value;
		};

		sampleSlots = moduleDef[\sampleSlots];
		if (sampleSlots.notNil) {
			// TODO: validate against ugenGraphFunc
			expandedModuleDef[\sampleSlots] = sampleSlots.value;
		};

		expandedModuleDef;
	};
};

var initServerResources = { |instance|
	if (instance[\trace]) { Char.nl.post; };
	sendSynthDefsToServer.value(instance[\moduleDefs], instance[\trace]); // TODO: it should be possible to decrease r init time by sending synthdefs lazily to server (add this as an option?)

	instance[\topGroup] = Group.tail(instance[\group]);

	Server.default.sync;

	instance[\taps] = Array.fill(instance[\numTaps]) { (bus: Bus.control, active: false) };
};

var sendSynthDefsToServer = { |moduleDefs, trace|
	moduleDefs do: { |moduleDef|
		sendModuleSynthDefToServer.value(moduleDef, trace);
	};

	SynthDef(\r_tapout, { |in, out|
		Out.kr(out, A2K.kr(In.ar(in)));
	}).add;

	SynthDef(\r_patch, { |in, out|
		Out.ar(out, In.ar(in, 1));
	}).add;

	SynthDef(\r_patch_feedback, { |in, out|
		Out.ar(out, InFeedback.ar(in, 1));
	}).add;
};

var newCommand = { |self, name, kind|
	var moduleDef = lookupModuleDefByKind.value(self, kind.asSymbol);

/*
	inline function optimization
*/
	var spec;
	var group;
	var inputPatchCordGroup;
	var processingGroup;
	var tapGroup;
	var inbusses;
	var outbusses;
	var visualbusses;
	var sampleSlotBuffers;
	var module;
	var finalizeFunc;

	if (moduleDef.isNil) {
		postUnableToCreateDueToInvalidModuleTypeError.value(name, kind);
	} {
		if (lookupModuleByName.value(self, name).notNil) {
			postUnableToCreateDueToAlreadyExistingModuleError.value(name);
		} {
			if (isValidModuleName.value(name)) {
				/* var */ spec = getModuleDefSpec.value(moduleDef);
				/* var */ group = Group.tail(self[\topGroup]);
				/* var */ inputPatchCordGroup = spec[\inputs].notEmpty.if { Group.tail(group) };
				/* var */ processingGroup = Group.tail(group);
				/* var */ tapGroup = Group.tail(group);
				/* var */ inbusses = spec[\inputs].collect { |input| input -> Bus.audio };
				/* var */ outbusses = spec[\outputs].collect { |output| output -> Bus.audio };
				/* var */ visualbusses = spec[\visuals].collect { |visual| visual -> Bus.control };
				/* var */ sampleSlotBuffers = spec[\sampleSlots].collect { |sampleSlotAssoc|
					var sampleSlotName = sampleSlotAssoc.key;
					var sampleSlotSpec = sampleSlotAssoc.value;
					sampleSlotName -> sampleSlotSpec[\Channels].collect { |channelCount|
						var buffer = Buffer.alloc(numChannels: channelCount, numFrames: 1); // TODO: allocating one frame to suppress warning message
						if (self[\trace]) {
							"buffer % created for sample slot % (channel count %)".format(buffer.bufnum, (name++":"++sampleSlotName).quote, channelCount);
						};

						channelCount -> buffer;
					};
				};
				/* var */ module = (
					name: name.asSymbol,
					kind: kind.asSymbol,
					moduleDef: moduleDef,
					serverContext: (
						group: group,
						inputPatchCordGroup: inputPatchCordGroup,
						processingGroup: processingGroup,
						tapGroup: tapGroup,
						inbusses: inbusses,
						outbusses: outbusses,
						visualbusses: visualbusses,
						sampleSlotBuffers: sampleSlotBuffers
					),
					// TODO: refactor to local asDict that takes an array of associations, in order to support oldish SuperCollider versions
					inputPatchCords: IdentityDictionary.newFrom(
						spec[\inputs].collect { |input|
							[
								input, // key
								() // value
							]
						}.flatten
					), // TODO: better to bundle this together with inbusses (?)
				);

				/* var */ finalizeFunc = {
					module[\synth] = Synth(
						getModuleDefSynthDefName.value(moduleDef),
						getDefaultModuleSynthArgs.value(
							moduleDef,
							inbusses,
							outbusses,
							visualbusses,
							(
								mainInBus: self[\inBus],
								mainOutBus: self[\outBus]
							),
							sampleSlotBuffers
						),
						target: processingGroup
					);

					self[\modules] = self[\modules].add(module);
				};

				if (module[\serverContext][\sampleSlotBuffers].notEmpty) {
					forkIfNeeded { // server.sync required to suppress "Buffer UGen: no buffer data" message for SynthDefs using samples
						Server.default.sync;
						finalizeFunc.value;
					};
				} {
					finalizeFunc.value;
				};
			} {
				postModuleNameIsInvalidError.value(name);
			};
		};
	};
};

var connectCommand = { |self, moduleOutputRef, moduleInputRef|
/*
	inline function optimization
*/
	var sourceModuleRef, outputRef;
	var destModuleRef, inputRef;
	var sourceModule, destModule;
	var sourceModuleIndex, destModuleIndex;

	if (isValidModuleOutputName.value(moduleOutputRef).not) {
		postInvalidModuleOutputNameError.value(moduleOutputRef);
	} {
		if (isValidModuleInputName.value(moduleInputRef).not) {
			postInvalidModuleInputNameError.value(moduleInputRef);
		} {
			if (isConnected.value(self, moduleOutputRef, moduleInputRef)) {
				postInputAndOutputIsConnectedError.value(moduleOutputRef, moduleInputRef);
			} {
				/*
				var sourceModuleRef, outputRef;
				var destModuleRef, inputRef;
				var sourceModule, destModule;
				var sourceModuleIndex, destModuleIndex;
				*/

				# sourceModuleRef, outputRef = parseModuleOutputReference.value(moduleOutputRef);
				# destModuleRef, inputRef = parseModuleInputReference.value(moduleInputRef);

				sourceModule = lookupModuleByName.value(self, sourceModuleRef);

				if (sourceModule.isNil) {
					postModuleNotFoundError.value(sourceModuleRef, self[\modules]);
				} {
					sourceModuleIndex = self[\modules].indexOf(sourceModule);

					destModule = lookupModuleByName.value(self, destModuleRef);

					if (destModule.isNil) {
						postModuleNotFoundError.value(destModuleRef, self[\modules]);
					} {
						destModuleIndex = self[\modules].indexOf(destModule);

						if (moduleHasOutputNamed.value(sourceModule, outputRef).not) {
							postInvalidModuleOutputError.value(sourceModule, outputRef);
						} {
							if (moduleHasInputNamed.value(destModule, inputRef).not) {
								postInvalidModuleInputError.value(destModule, inputRef);
							} {
								destModule[\inputPatchCords][inputRef.asSymbol][moduleOutputRef.asSymbol] = Synth(
									if (sourceModuleIndex >= destModuleIndex, \r_patch_feedback, \r_patch),
									[
										\in, sourceModule[\serverContext][\outbusses].detect { |busAssoc| busAssoc.key == outputRef.asSymbol }.value,
										\out, destModule[\serverContext][\inbusses].detect { |busAssoc| busAssoc.key == inputRef.asSymbol }.value,
										\level, 1.0
									],
									destModule[\serverContext][\inputPatchCordGroup],
									\addToTail
								);
							}
						}
					}
				}
			}
		}
	}
};

var disconnectCommand = { |self, moduleOutputRef, moduleInputRef|
	disconnect.value(self, moduleOutputRef, moduleInputRef);
};

var disconnect = { |self, moduleOutputRef, moduleInputRef|
	var sourceModuleRef, outputRef;
	var destModuleRef, inputRef;
	var sourceModule, destModule;

	if (isValidModuleOutputName.value(moduleOutputRef).not) {
		postInvalidModuleOutputNameError.value(moduleOutputRef);
	} {
		if (isValidModuleInputName.value(moduleInputRef).not) {
			postInvalidModuleInputNameError.value(moduleInputRef);
		} {
			# sourceModuleRef, outputRef = parseModuleOutputReference.value(moduleOutputRef); // the fact that this module and output exists is inferred due to isConnected call
			# destModuleRef, inputRef = parseModuleInputReference.value(moduleInputRef); // the fact that this module and input exists is inferred due to isConnected call

			sourceModule = lookupModuleByName.value(self, sourceModuleRef);

			if (sourceModule.isNil) {
				postModuleNotFoundError.value(sourceModuleRef, self[\modules]);
			} {
				destModule = lookupModuleByName.value(self, destModuleRef);

				if (destModule.isNil) {
					postModuleNotFoundError.value(destModuleRef, self[\modules]);
				} {
					if (moduleHasOutputNamed.value(sourceModule, outputRef).not) {
						postInvalidModuleOutputError.value(sourceModule, outputRef);
					} {
						if (moduleHasInputNamed.value(destModule, inputRef).not) {
							postInvalidModuleInputError.value(destModule, inputRef);
						} {
							if (isConnected.value(self, moduleOutputRef, moduleInputRef)) {
								destModule = lookupModuleByName.value(self, destModuleRef);

								destModule[\inputPatchCords][inputRef.asSymbol][moduleOutputRef.asSymbol].free;
								destModule[\inputPatchCords][inputRef.asSymbol][moduleOutputRef.asSymbol] = nil;
							} {
								postInputAndOutputIsNotConnectedError.value(moduleOutputRef, moduleInputRef);
							};
						};
					};
				};
			};
		};
	};
};

var deleteCommand = { |self, moduleRef|
	if (isValidModuleName.value(moduleRef)) {
		deleteModule.value(self, moduleRef);
	} {
		postModuleNameIsInvalidError.value(moduleRef);
	};
};

var setCommand = { |self, moduleParameterRef, value|
	var moduleRef, parameterRef, module, spec;

	if (isValidModuleParameterName.value(moduleParameterRef).not) {
		postInvalidModuleParameterNameError.value(moduleParameterRef);
	} {
		# moduleRef, parameterRef = parseModuleParameterReference.value(moduleParameterRef);

		module = lookupModuleByName.value(self, moduleRef);
		if (module.isNil) {
			postModuleNotFoundError.value(moduleRef, self[\modules]);
		} {
			spec = getModuleDefSpec.value(module[\moduleDef]);

			if (spec[\parameters].includes(parameterRef.asSymbol)) {
				setModuleParam.value(module, parameterRef, value);
			} {
				postInvalidModuleParameterError.value(module, parameterRef, )
			}
		};
	};
};

var bulksetCommand = { |self, bundle|
/*
	TODO
	if (isValidBundle.value(bundle).not) {
		postInvalidBundleError.value(name);
	} {
*/
		Server.default.makeBundle(nil) { // TODO: consider udp package size limitations and bulksetCommand
			bundle.asString.split($ ).clump(2).do { |cmd, i|
				setCommand.value(cmd[0], cmd[1]); // TODO: use internal method?
			}
		};
/*
	};
*/
};

var newmacroCommand = { |self, name, bundle|
	var macro;
	var bus;
	var moduleParameterRefs;

	if (isValidMacroName.value(name).not) {
		postInvalidMacroNameError.value(name);
	} {
		moduleParameterRefs = bundle.asString.split($ );

		if (areValidMacroModuleParameters.value(moduleParameterRefs).not) {
			postInvalidMacroModuleParametersError.value(name, moduleParameterRefs);
		} {
			if (moduleParametersHaveConsistentControlSpecs.value(self, moduleParameterRefs).not) {
				postModuleParameterControlSpecsAreInconsistent.value(name, moduleParameterRefs);
			} {
				bus = Bus.control;

				macro = (
					moduleParameterRefs: moduleParameterRefs,
					bus: bus
					controlSpec: getControlSpecByModuleParameterRef.value(self, moduleParameterRefs.first)
				);

				Server.default.makeBundle(nil) {
					macro[\moduleParameterRefs].do { |moduleParameterRef|
						var moduleRef, parameterRef, module, spec;

						# moduleRef, parameterRef = parseModuleParameterReference.value(moduleParameterRef);

						module = lookupModuleByName.value(self, moduleRef);
						if (module.isNil) { // TODO: to be handled above
							postModuleNotFoundError.value(moduleRef, self[\modules]);
						} {
							spec = getModuleDefSpec.value(module[\moduleDef]);

							if (spec[\parameters].includes(parameterRef.asSymbol)) { // TODO: to be handled above
								mapModuleParam.value(module, parameterRef, bus);
							} {
								postInvalidModuleParameterError.value(module, parameterRef)
							}
						}
					}
				};

				self[\macros][name.asSymbol] = macro;
			};
		};
	};
};

var deletemacroCommand = { |self, name|
	var macros;

	if (isValidMacroName.value(name).not) {
		postInvalidMacroNameError.value(name);
	} {
		macros = self[\macros];
		macros[name.asSymbol][\bus].free;
		macros[name.asSymbol][\moduleParameterRefs].do {
			// TODO: unmap control
			// Reset to current bus value or default module def parameter controlspec value - or is this needed at all?
		};
		macros[name.asSymbol] = nil;
	};
};

var macrosetCommand = { |self, name, value|
	if (isValidMacroName.value(name).not) {
		postInvalidMacroNameError.value(name);
	} {
		// TODO: validate presence of macro
		// TODO: controlSpecs are not regarded here! only allow macro creation of params with same controlSpec in newmacro and constrain here?
		// TODO: map using the ControlSpec!
		self[\macros][name.asSymbol][\bus].set(value);
	};
};

var readsampleCommand = { |self, moduleSampleSlotRef, path|
	// TODO: this.lookupSampleSlot(...)
	var moduleRef, sampleSlotRef;
	var module;

/*
	inline function optimization
*/
	var sampleSlotBuffers;
	var channelCount;
	var buffer;

	if (isValidModuleSampleSlotName.value(moduleSampleSlotRef).not) {
		postInvalidModuleSampleSlotNameError.value(moduleSampleSlotRef);
	} {
		# moduleRef, sampleSlotRef = parseModuleSampleSlotReference.value(moduleSampleSlotRef);

		module = lookupModuleByName.value(self, moduleRef);

		if (module.isNil) {
			postModuleNotFoundError.value(moduleRef, self[\modules]);
		} {
			if (moduleHasSampleSlotNamed.value(module, sampleSlotRef).not) {
				postInvalidModuleSampleSlotError.value(module, sampleSlotRef);
			} {
				if (File.exists(path)) {
					/* var */ sampleSlotBuffers = lookupSampleSlotBuffersByName.value(module, sampleSlotRef); // TODO: naming, for clarity, this is not the complete sampleslotbuffers object, but only for one sampleslot

					// TODO: ensure that path is a soundfile? -- done below?

					/* var */ channelCount = getSoundFileNumChannels.value(path);

					if (channelCount.isNil) {
						postFileIsNotASoundFileError.value(path);
					} {
						if (sampleSlotBuffers.keys.includes(channelCount)) { // TODO: moduleSampleSlotSupportsChannelCount.value(channelCount)
							/* var */ buffer = sampleSlotBuffers[channelCount];

							buffer.allocRead(path);

							forkIfNeeded {
								Server.default.sync;
								buffer.updateInfo(path);
								Server.default.sync;
								if (self[\trace]) {
									"sample % (% channels) loaded into sample slot % (buffer %)"
										.format(path.quote, channelCount, (module[\name].asString++":"++sampleSlotRef).quote, buffer.bufnum, moduleRef).inform;
								};
								setModuleSampleSlotChannelCount.value(module, sampleSlotRef, channelCount)
							};
						} {
							postModuleSampleSlotDoesNotSupportChannelCountError.value(module, sampleSlotRef, channelCount);
						}
					}
				} {
					postFileDoesNotExistError.value(path);
				}
			}
		}
	}
};

/*
TODO
how to know what buffer (channel count) to use when writing?
writesampleCommand { |moduleSampleSlotRef, path| // TODO: factor out Command prefix
};
*/

var tapoutputCommand = { |self, index, moduleOutputRef|
	if (isValidModuleOutputName.value(moduleOutputRef).not) {
		postInvalidModuleOutputNameError.value(moduleOutputRef);
	} {
		ifTapIndexWithinBoundsDo.value(self, index) {
			var moduleRef, outputRef;
			var module;

	/*
			inline function optimization
	*/
			var moduleOutputBus;
			var targetGroup;
			var tap;

			// TODO: validate output ref

			# moduleRef, outputRef = parseModuleOutputReference.value(moduleOutputRef);

			module = lookupModuleByName.value(self, moduleRef);

			if (module.isNil) {
				postModuleNotFoundError.value(moduleRef, self[\modules]);
			} {
				if (moduleHasOutputNamed.value(module, outputRef).not) {
					postInvalidModuleOutputError.value(module, outputRef);
				} {
	/*
		TODO: test that this work and then remove
					var moduleServerContext = module[\serverContext]; // TODO: extract this elsewhere too
					var moduleOutputBus = moduleServerContext[\outbusses].detect { |busAssoc| busAssoc.key == outputRef.asSymbol }.value; // TODO: DRY
					var targetGroup = moduleServerContext[\tapGroup];
	*/
					/* var */ moduleOutputBus = lookupModuleOutputBus.value(module, outputRef);
					/* var */ targetGroup = lookupModuleTapGroup.value(module);
					/* var */ tap = self[\taps][index];

					if (tapIsSet.value(self, index)) {
						clearTap.value(self, index);
					};

					tap[\synth] = Synth(
						defName: \r_tapout,
						args: [\in, moduleOutputBus, \out, tap[\bus]],
						target: targetGroup,
						addAction: \addToHead
					);
					tap[\moduleOutputRef] = moduleOutputRef;
					tap[\active] = true;
				};
			};
		};
	};
};

var tapclearCommand = { |self, index|
	ifTapIndexWithinBoundsDo.value(self, index) {
		clearTap.value(self, index);
	};
};

var getTapBus = { |self, tapIndex| // TODO: this is currently public API
	self[\taps][tapIndex][\bus]
};

var getVisualBus = { |self, moduleVisualRef| // TODO: this is currently public API
	var moduleRef, visualRef;
	var module;

/*
	inline function optimization
*/
	var serverContext, visualbusses, bus;

	if (isValidModuleVisualName.value(moduleVisualRef).not) {
		postInvalidModuleVisualNameError.value(moduleVisualRef);
	} {
		# moduleRef, visualRef = parseModuleVisualReference.value(moduleVisualRef);

		module = lookupModuleByName.value(self, moduleRef);

		if (module.isNil) {
			postModuleNotFoundError.value(moduleRef);
		} {
			if (moduleHasVisualNamed.value(module, visualRef).not) {
				postInvalidModuleVisualError.value(module, visualRef)
			} {
				/* var serverContext, visualbusses, bus; */
				serverContext = module[\serverContext];
				visualbusses = serverContext[\visualbusses];
				bus = visualbusses.detect { |busAssoc| busAssoc.key == visualRef.asSymbol }.value;
				bus
			};
		};
	};
};

/* Parsing / constructing references */

var parseModuleParameterReference = { |reference|
	reference.asString.split(moduleParameterRefDelimiter);
};

var parseModuleInputReference = { |reference|
	reference.asString.split(moduleInputRefDelimiter);
};

var constructModuleInputReference = { |moduleRef, inputRef|
	(moduleRef.asString++moduleInputRefDelimiter.asString++inputRef.asString).asSymbol
};

var parseModuleOutputReference = { |reference|
	reference.asString.split(moduleOutputRefDelimiter);
};

var constructModuleOutputReference = { |moduleRef, outputRef|
	(moduleRef.asString++moduleOutputRefDelimiter.asString++outputRef.asString).asSymbol
};

var parseModuleVisualReference = { |reference|
	reference.asString.split(moduleVisualRefDelimiter);
};

var parseModuleSampleSlotReference = { |reference|
	reference.asString.split(moduleSampleSlotRefDelimiter);
};

/* Guts */

var lookupModuleOutputBus = { |module, outputRef|
	var moduleServerContext = module[\serverContext];
	moduleServerContext[\outbusses].detect { |busAssoc| busAssoc.key == outputRef.asSymbol }.value;
};

var lookupModuleTapGroup = { |module|
	module[\serverContext][\tapGroup];
};

var getSoundFileNumChannels = { |path|
	var numChannels;
	var soundFile = SoundFile.openRead(path);

	// TODO: ensure that path is a soundfile

	if (soundFile.notNil) {
		numChannels = soundFile.numChannels;
		soundFile.close;
	};
	numChannels;
};

var lookupSampleSlotBuffersByName = { |module, sampleSlotName|
	var sampleSlotBufferDict = module[\serverContext][\sampleSlotBuffers].asDict;
	sampleSlotBufferDict[sampleSlotName.asSymbol].asDict;
};

/*
TODO
lookupSampleSlot { |moduleSampleSlotRef|
};
*/

// TODO: consider exploding this in each occurence, or adopt this way of handling validations everywhere
var ifTapIndexWithinBoundsDo = { |self, tapIndex, func|
	if ((0 <= tapIndex) and: (tapIndex < self[\numTaps])) {
		func.value;
	} {
		postTapIndexNotWithinBoundsError.value(self, tapIndex);
	};
};

var deleteModule = { |self, moduleRef|
	var moduleToDelete = lookupModuleByName.value(self, moduleRef);

/*
	inline function optimization
*/
	var serverContext;

	if (moduleToDelete.isNil) {
		postModuleNotFoundError.value(moduleRef, self[\modules]);
	} {
		/* var */ serverContext = moduleToDelete[\serverContext];

		clearTapsForModule.value(self, moduleRef);

		disconnectModulePatchCords.value(self, moduleToDelete);

		moduleToDelete[\synth].free;
		serverContext[\group].free;
		serverContext[\inbusses] do: { |inputBusAssoc| inputBusAssoc.value.free };
		serverContext[\outbusses] do: { |outputBusAssoc| outputBusAssoc.value.free };
		serverContext[\visualbusses] do: { |visualBusAssoc| visualBusAssoc.value.free };

		forkIfNeeded {
			Server.default.sync; // server.sync required to suppress "Buffer UGen: no buffer data" message for SynthDefs using samples
			serverContext[\sampleSlotBuffers] do: { |sampleSlotAssoc|
				var sampleSlotName = sampleSlotAssoc.key;
				var sampleSlotBuffers = sampleSlotAssoc.value;
				sampleSlotBuffers do: { |sampleSlotBufferAssoc|
					var channelCount = sampleSlotBufferAssoc.key;
					var buffer = sampleSlotBufferAssoc.value;
					var bufnum = buffer.bufnum;
					buffer.free;
					if (self[\trace]) {
						"buffer % for sample slot % (channel count %) freed".format(bufnum, (moduleToDelete[\name]++":"++sampleSlotName).quote, channelCount);
					};
				}
			};
			self[\modules].remove(moduleToDelete);
		}
	};
};

var clearTapsForModule = { |self, name|
	self[\taps].do { |tap, tapIndex|
		var moduleRef, output;

		# moduleRef, output = parseModuleOutputReference.value(tap[\moduleOutputRef]);

		if (moduleRef == name) {
			clearTap.value(self, tapIndex);
		};
	};
};

var clearTap = { |self, tapIndex|
	var tap = self[\taps][tapIndex];
	tap[\synth].free;
	tap[\synth] = nil;
	tap[\moduleOutputRef] = nil;
};

var tapIsSet = { |self, index|
	self[\taps][index][\active];
};

var moduleHasParameterNamed = { |module, name|
	getModuleDefSpec.value(module[\moduleDef])[\parameters].any { |input| input == name.asSymbol }
};

var moduleHasInputNamed = { |module, name|
	getModuleDefSpec.value(module[\moduleDef])[\inputs].any { |input| input == name.asSymbol }
};

var moduleHasOutputNamed = { |module, name|
	getModuleDefSpec.value(module[\moduleDef])[\outputs].any { |output| output == name.asSymbol }
};

var moduleHasVisualNamed = { |module, name|
	getModuleDefSpec.value(module[\moduleDef])[\visuals].any { |visual| visual == name.asSymbol }
};

var moduleHasSampleSlotNamed = { |module, name|
	getModuleDefSpec.value(module[\moduleDef])[\sampleSlots].any { |sampleSlotAssoc|
		sampleSlotAssoc.key == name.asSymbol
	}
};

var isConnected = { |self, moduleOutputRef, moduleInputRef|
	var destModuleRef, inputRef, destModule;

/*
	inline function optimization
*/
	var patchCordsForModuleInput;

	# destModuleRef, inputRef = parseModuleInputReference.value(moduleInputRef);
	destModule = lookupModuleByName.value(self, destModuleRef);
	if (destModule.isNil) {
		postModuleNotFoundError.value(destModuleRef, self[\modules]);
		false; // TODO: correct? throw error instead?
	} {
		/* var */ patchCordsForModuleInput = destModule[\inputPatchCords][inputRef.asSymbol];
		if (patchCordsForModuleInput.isNil) {
			postInvalidModuleInputError.value(destModule, inputRef);
			false; // TODO: correct? throw error instead?
		} {
			patchCordsForModuleInput.keys.any { |patchedModuleOutput| patchedModuleOutput == moduleOutputRef.asSymbol };
		}
	}
};

var disconnectModulePatchCords = { |self, moduleToDisconnect|
	var spec = getModuleDefSpec.value(moduleToDisconnect[\moduleDef]);
	var moduleInputs = spec[\inputs].collect { |input|
		constructModuleInputReference.value(moduleToDisconnect[\name], input);
	};
	var moduleOutputs = spec[\outputs].collect { |output|
		constructModuleOutputReference.value(moduleToDisconnect[\name], output);
	};
	[getAllModuleOutputs.value(self), moduleInputs].allTuples.select { |tuple|
		isConnected.value(self, tuple[0], tuple[1]);
	} ++ [moduleOutputs, getAllModuleInputs.value(self)].allTuples.select { |tuple|
		isConnected.value(self, tuple[0], tuple[1]);
	}.do { |tuple|
		disconnect.value(self, tuple[0], tuple[1]);
	}
};

var getAllModuleOutputs = { |self|
	self[\modules]
		.collect { |module|
			var spec = getModuleDefSpec.value(module[\moduleDef]);
			spec[\outputs].collect { |output|
				constructModuleOutputReference.value(module[\name], output);
			}.asArray
		}.flatten
};

var getAllModuleInputs = { |self|
	self[\modules]
		.collect { |module|
			var spec = getModuleDefSpec.value(module[\moduleDef]);
			spec[\inputs].collect { |input|
				constructModuleInputReference.value(module[\name], input);
			}.asArray
		}.flatten
};

var isValidModuleInputName = { |ref|
	var module, input;

	ref = ref.asString;
	if (ref.contains(moduleInputRefDelimiter)) {
		# module, input = parseModuleInputReference.value(ref);
		isValidModuleName.value(module) and: isValidInOutputName.value(input);
	} {
		false
	};
};

var isValidModuleOutputName = { |ref|
	var module, output;

	ref = ref.asString;
	if (ref.contains(moduleOutputRefDelimiter)) {
		# module, output = parseModuleOutputReference.value(ref);
		isValidModuleName.value(module) and: isValidInOutputName.value(output);
	} {
		false
	};
};

var isValidModuleParameterName = { |ref|
	var module, parameter;

	ref = ref.asString;
	if (ref.contains(moduleParameterRefDelimiter)) {
		# module, parameter = parseModuleParameterReference.value(ref);
		isValidModuleName.value(module) and: isValidParameterName.value(parameter);
	} {
		false
	};
};

var isValidModuleVisualName = { |ref|
	var module, visual;

	ref = ref.asString;
	if (ref.contains(moduleVisualRefDelimiter)) {
		# module, visual = parseModuleVisualReference.value(ref);
		isValidModuleName.value(module) and: isValidVisualName.value(visual);
	} {
		false
	};
};

var isValidModuleSampleSlotName = { |ref|
	var module, sampleSlot;

	ref = ref.asString;
	if (ref.contains(moduleSampleSlotRefDelimiter)) {
		# module, sampleSlot = parseModuleParameterReference.value(ref);
		isValidModuleName.value(module) and: isValidSampleSlotName.value(sampleSlot);
	} {
		false
	};
};

var isValidMacroName = { |name|
	isValidName.value(name);
};

var areValidMacroModuleParameters = { |moduleParameterRefs|
	moduleParameterRefs.every { |moduleParameterRef|
		isValidModuleParameterName.value(moduleParameterRef);
	};
};

var moduleParametersHaveConsistentControlSpecs = { |self, moduleParameterRefs|
	var firstControlSpec;
	var consistent;
	var i;

	if (moduleParameterRefs.size > 1 ) {
		consistent = true;
		i = 1;

		firstControlSpec = getControlSpecByModuleParameterRef.value(self, moduleParameterRefs.first);

		while (consistent and: (i < moduleParameterRefs.size)) {
			consistent = (firstControlSpec == getControlSpecByModuleParameterRef.value(self, moduleParameterRefs[i]));
			i = i + 1;
		};

		consistent;
	} {
		true;
	};
};

var getControlSpecByModuleParameterRef = { |self, moduleParameterRef|
	var moduleRef, parameterRef;
	var module;
	# moduleRef, parameterRef = parseModuleParameterReference.value(moduleParameterRef);
	module = lookupModuleByName.value(self, moduleRef);
	getControlSpecForModuleParameter.value(module, parameterRef);
};

var getControlSpecForModuleParameter = { |module, parameterRef|
	var paramControlSpecs = getModuleDefParamControlSpecs.value(module[\moduleDef]);
	paramControlSpecs[parameterRef];
};

var isValidModuleName = { |name|
	isValidName.value(name);
};

var isValidInOutputName = { |name|
	isValidName.value(name);
};

var isValidParameterName = { |name|
	isValidName.value(name);
};

var isValidSampleSlotName = { |name|
	isValidName.value(name);
};

var isValidVisualName = { |name|
	isValidName.value(name);
};

var isValidName = { |name|
	name = name.asString;
	name.every { |char|
		// Range($a.ascii, $z.ascii).includes(char.ascii) or: Range($A.ascii, $Z.ascii).includes(char.ascii) or: Range($0.ascii, $9.ascii).includes(char.ascii) // TODO: file sc Range bug
		var char2 = char.ascii;
		(($a.ascii <= char2) and: (char2 <= $z.ascii)) or: (($A.ascii <= char2) and: (char2 <=$Z.ascii)) or: (($0.ascii <= char2) and: (char2 <= $9.ascii)) or: (char == $_)
	}
};

var lookupModuleByName = { |self, name|
	name = name.asSymbol;
	self[\modules].detect { |module| module[\name] == name };
};

var getDefaultModuleSynthArgs = { |moduleDef, inbusses, outbusses, visualbusses, ioContext, sampleSlotBuffers|
	var defaults = getModuleDefDefaultSynthArgs.value(moduleDef, inbusses, outbusses, visualbusses, sampleSlotBuffers);

	case
	{ moduleDef[\name] == 'SoundIn' } {
		defaults ++ [\internal_In, ioContext[\mainInBus]]
	}
	{ moduleDef[\name] == 'SoundIn' } {
		defaults ++ [\internal_Out, ioContext[\mainOutBus]]
	} ?? defaults
};

var lookupModuleDefByKind = { |self, kind|
	self[\moduleDefs].detect { |moduleDef|
		getModuleDefName.value(moduleDef) == kind
	}
};

var free = { |self|
	deleteAllModules.value(self);
	self[\taps] do: { |tap|
		tap[\bus].free;
	};
	self[\topGroup].free;
};

var deleteAllModules = { |self|
	self[\modules].collect(_.name) do: { |modulename| // collect used to dup here since deleteCommand removes entries in modules
		deleteModule.value(self, modulename)
	};
};

var generateModuleDocs = { |self|
	self[\moduleDefs].collect { |moduleDef|
		generateModuleDocsForSingleModuleDef.value(moduleDef);
	}.join("\n")
};

/* RModule stuff */

var setModuleParam = { |module, parameter, value|
	var moduleDef = module[\moduleDef];
	var params = getModuleDefParams.value(moduleDef);
	var paramControlSpecs = getModuleDefParamControlSpecs.value(moduleDef);
	var param = params.detect { |param| param.key == parameter.asSymbol };

/*
	inline optimization
*/
	var name, controlSpec, constrainedParamValue;

	if (param.notNil) { // TODO: DRY
		name = ("param_"++param.key.asString).asSymbol;
		controlSpec = paramControlSpecs[name];
		constrainedParamValue = controlSpec.constrain(value);
		module[\synth].set(name, constrainedParamValue);
	}
};

var mapModuleParam = { |module, parameter, bus|
	var moduleDef = module[\moduleDef];
	var params = getModuleDefParams.value(moduleDef);
	var paramControlSpecs = getModuleDefParamControlSpecs.value(moduleDef);
	var param = params.detect { |param| param.key == parameter.asSymbol };
		var name;

	if (param.notNil) { // TODO: DRY
		name = ("param_"++param.key.asString).asSymbol;
		module[\synth].map(name, bus);
	}
};

var setModuleSampleSlotChannelCount = { |module, sampleSlotName, channelCount|
	var name;
	name = ("numchannels_"++sampleSlotName.asString).asSymbol;
	module[\synth].set(name, channelCount.asInteger);
};

var generateModuleDocsForSingleModuleDef = { |moduleDef|
	var spec = getModuleDefSpec.value(moduleDef);
	var inputs = spec[\inputs];
	var outputs = spec[\outputs];
	var parameters = spec[\parameters];
	var visuals = spec[\visuals];
	var sampleSlots = spec[\sampleSlots];

	"### " ++ moduleDef[\name].asString ++ "\n" ++
	"- Inputs:" ++
	if (
		inputs.isEmpty,
		" None",
		" " ++ inputs.collect { |inputRef|
			"`" ++ inputRef ++ "`"
		}.join(", ")
	) ++ "\n" ++
	"- Outputs:" ++
	if (
		outputs.isEmpty,
		" None",
		" " ++ outputs.collect { |outputRef|
			"`" ++ outputRef ++ "`"
		}.join(", ")
	) ++ "\n" ++
	"- Parameters:" ++
	if (
		parameters.isEmpty,
		" None",
		"\n" ++
		parameters.collect { |parameterRef|
			"\t- `" ++ parameterRef ++ "`" // TODO: include description derived from ControlSpec
		}.join($\n)
	) ++ "\n"
	"- Visuals:" ++
	if (
		visuals.isEmpty,
		" None",
		"\n" ++
		visuals.collect { |visual|
			"\t- `" ++ visual ++ "`" // TODO: include description, derived from ControlSpec(?)
		}.join($\n)
	) ++ "\n" ++
	"- Sample Slots:" ++
	if (
		sampleSlots.isEmpty,
		" None",
		"\n" ++
		sampleSlots.collect { |sampleSlotRef|
			"\t- `" ++ sampleSlotRef ++ "`" // TODO: include description
		}.join($\n)
	) ++ "\n"
};

var sendModuleSynthDefToServer = { |moduleDef, trace|
	var name = getModuleDefName.value(moduleDef);
	var synthDefName = getModuleDefSynthDefName.value(moduleDef);
	var ugenGraphFunc = getModuleDefUgenGraphFunc.value(moduleDef);
	var lagTimes = getModuleDefSynthDefLagTimes.value(moduleDef);
	var metadata = getModuleDefSynthDefMetadata.value(moduleDef);

	if (trace) {
		"Module %: spawning SynthDef %...".format(name.asString.quote, synthDefName.asString.quote).postln;
	};

	SynthDef(synthDefName, ugenGraphFunc, lagTimes, metadata: metadata).add;

	if (trace) {
		"...OK. SynthDef % was sent to server".format(synthDefName.asString.quote).postln;
		"".postln;
	};
};

var getModuleDefSynthDefName = { |moduleDef|
	("r_" ++ moduleDef[\name].asString).asSymbol
};

var getModuleDefSynthDefLagTimes = { |moduleDef|
	var paramLagTimes = getModuleDefParamLagTimes.value(moduleDef);
	moduleDef[\ugenGraphFunc].def.argNames.collect { |argName|
		if ( argName.asString.beginsWith("param_") ) {
			paramLagTimes[argName]
		} { nil }
	};
};

var getModuleDefSynthDefMetadata = { |moduleDef|
	(specs: getModuleDefParamControlSpecs.value(moduleDef))
};

var getModuleDefSpec = { |moduleDef|
	var sampleSlotDict = moduleDef[\sampleSlots] !? _.asDict;
	(
		inputs: lookupModuleDefArgNameSuffixesPrefixedBy.value(moduleDef, 'in_'),
		outputs: lookupModuleDefArgNameSuffixesPrefixedBy.value(moduleDef, 'out_'),
		parameters: lookupModuleDefArgNameSuffixesPrefixedBy.value(moduleDef, 'param_'),
		visuals: lookupModuleDefArgNameSuffixesPrefixedBy.value(moduleDef, 'visual_'),
		sampleSlots: lookupModuleDefArgNameSuffixesPrefixedBy.value(moduleDef, 'numchannels_').collect { |sampleSlotName|
			var spec = sampleSlotDict[sampleSlotName];
			sampleSlotName -> spec
		},
	)
};

var lookupModuleDefArgNameSuffixesPrefixedBy = { |moduleDef, token|
	token = token.asString;
	moduleDef[\ugenGraphFunc].def.argNames.select { |argName|
		argName.asString.beginsWith(token)
	}.collect { |argName|
		argName.asString[token.size..].asSymbol
	}
};

var getModuleDefDefaultSynthArgs = { |moduleDef, inbusses, outbusses, visualbusses, sampleSlotBuffers|
	var spec = getModuleDefSpec.value(moduleDef);
	var paramControlSpecs = getModuleDefParamControlSpecs.value(moduleDef);
	(
		spec[\inputs].collect { |inputName|
			[
				("in_"++inputName.asString).asSymbol,
				inbusses.detect { |busAssoc| busAssoc.key == inputName.asSymbol }.value
			] // TODO: report error when busAssoc not found
		} ++
		spec[\outputs].collect { |outputName|
			[
				("out_"++outputName.asString).asSymbol,
				outbusses.detect { |busAssoc| busAssoc.key == outputName.asSymbol }.value
			] // TODO: report error when busAssoc not found
		} ++
		spec[\parameters].collect { |parameterName|
			var name = ("param_"++parameterName.asString).asSymbol;
			var controlSpec = paramControlSpecs[name]; // TODO: report error when controlSpec is not found / or rely on .asSpec
			[name, controlSpec.default]
		} ++
		spec[\visuals].collect { |visualName|
			var name = ("visual_"++visualName.asString).asSymbol;
			[
				name,
				visualbusses.detect { |busAssoc| busAssoc.key == visualName.asSymbol }.value
			]
		}
		++
		sampleSlotBuffers.collect { |sampleSlotBuffersPerChannelAssoc|
			var sampleSlotName = sampleSlotBuffersPerChannelAssoc.key;
			var buffersPerChannel = sampleSlotBuffersPerChannelAssoc.value;
			[
				("bufnums_"++sampleSlotName.asString).asSymbol,
				buffersPerChannel.collect { |channelCountBufferAssoc|
					var buffer = channelCountBufferAssoc.value;
					buffer
				}
			]
		}
	).flatten
};

var getModuleDefParamLagTimes = { |moduleDef|
	var params = getModuleDefParams.value(moduleDef);
	if (params.notNil) {
		// TODO: refactor to local asDict that takes an array of associations
		IdentityDictionary.newFrom(
			params.collect { |paramAssoc|
				var paramAssocValue = paramAssoc.value;
				[
					("param_"++paramAssoc.key).asSymbol, // key
					// value ...
					if (paramAssocValue.class == Event) {
						paramAssocValue[\LagTime]
					} {
						nil
					}
				];
			}.flatten;
		)
	}
};

var getModuleDefParamControlSpecs = { |moduleDef|
	var params = getModuleDefParams.value(moduleDef);
	if (params.notNil) {
		// TODO: refactor to local asDict that takes an array of associations
		IdentityDictionary.newFrom(
			params.collect { |paramAssoc|
				var paramAssocValue = paramAssoc.value;
				[
					("param_"++paramAssoc.key).asSymbol, // key
					// value ...
					if (paramAssocValue.class == ControlSpec) { // TODO: DRY this up
						paramAssocValue
					} {
						// TODO: Event assumed
						paramAssocValue[\Spec]
					}
				]
			}.flatten
		)
	}
};

var getModuleDefName = { |moduleDef|
	moduleDef[\name]
};

var getModuleDefUgenGraphFunc = { |moduleDef|
	moduleDef[\ugenGraphFunc]
};

var getModuleDefParams = { |moduleDef|
	moduleDef[\params]
};

/* Information */

var postAutobootingServerInformation = {
	"Booting Server %".format(Server.default).inform;
};

/* Errors */

var postServerNotRunningError = { 
	"Server % is not running".format(Server.default).error;
};

var postTapIndexNotWithinBoundsError = { |self, tapIndex|
	"tap index not within bounds: tapIndex % referred, only % taps available".format(tapIndex, self[\numTaps]).error;
};

var postModuleSampleSlotDoesNotSupportChannelCountError = { |module, sampleSlotRef, channelCount|
	var sampleSlotBuffers = lookupSampleSlotBuffersByName.value(module, sampleSlotRef); // TODO: naming, for clarity, this is not the complete sampleslotbuffers object, but only for one sampleslot
	"sample slot % for % module named % does not support channel count % (supported channel counts are %)".format(
		sampleSlotRef.asString.quote,
		module[\kind].asString.quote,
		module[\name].asString.quote,
		channelCount,
		sampleSlotBuffers.keys.join(", ")
	).error;
};

var postFileDoesNotExistError = { |path|
	"file % does not exist.".format(path.quote).error;
};

var postFileIsNotASoundFileError = { |path|
	"file % is not a sound file.".format(path.quote).error;
};

var postInvalidMacroNameError = { |name|
	"macro name % is invalid.".format(name.asString.quote).error;
};

var postInvalidMacroModuleParametersError = { |name, moduleParameterRefs|
	var invalidRefs = moduleParameterRefs.select { |moduleParameterRef|
		isValidModuleParameterName.value(moduleParameterRef).not;
	};
	"macro % not created: module parameter refs % are invalid".format(
		name.asString.quote,
		invalidRefs.collect { |ref| ref.asString }.join(", ").quote
	).error; // TODO: if none, this looks weird, fix so that it says "no possible sample slots"
};

var postModuleParameterControlSpecsAreInconsistent = { |name, moduleParameterRefs|
	// TODO
};

var postInvalidModuleSampleSlotError = { |module, sampleSlotRef|
	var moduleDef = module[\moduleDef];
	var spec = getModuleDefSpec.value(moduleDef);
	var possibleSampleSlotsList = spec[\sampleSlots].collect{ |item| item.asString.quote }.join(", ");
	"invalid sample slot % for % module named % (possible sample slots are %)".format(
		sampleSlotRef.asString.quote,
		module[\kind].asString.quote,
		module[\name].asString.quote,
		possibleSampleSlotsList
	).error; // TODO: if none, this looks weird, fix so that it says "no possible sample slots"
};

var postInvalidModuleVisualNameError = { |ref|
	"module visual reference % does not conform to module visual syntax ([ModuleName]%[VisualName])".format(
		ref.asString.quote,
		moduleVisualRefDelimiter.asString
	).error;
};

var postInvalidModuleSampleSlotNameError = { |ref|
	"module sample slot reference % does not conform to module sample slot syntax ([ModuleName]%[SampleSlotName])".format(
		ref.asString.quote,
		moduleParameterRefDelimiter.asString
	).error;
};

var postInvalidModuleParameterNameError = { |ref|
	"module parameter reference % does not conform to module parameter syntax ([ModuleName]%[ParameterName])".format(
		ref.asString.quote,
		moduleParameterRefDelimiter.asString
	).error;
};

var postInvalidModuleOutputNameError = { |ref|
	"module output reference % does not conform to module output syntax ([ModuleName]%[OutputName])".format(
		ref.asString.quote,
		moduleOutputRefDelimiter.asString
	).error;
};

var postInvalidModuleInputNameError = { |ref|
	"module input reference % does not conform to module input syntax ([ModuleName]%[InputName])".format(
		ref.asString.quote,
		moduleInputRefDelimiter.asString
	).error;
};

var postInputAndOutputIsConnectedError = { |moduleOutputRef, moduleInputRef|
	"module out % is already connected to module in %".format(
		moduleOutputRef.asString.quote,
		moduleInputRef.asString.quote
	).error;
};

var postInputAndOutputIsNotConnectedError = { |moduleOutputRef, moduleInputRef|
	"module out % is not connected to module in %".format(
		moduleOutputRef.asString.quote,
		moduleInputRef.asString.quote
	).error;
};

var postModuleNameIsInvalidError = { |name|
	"module name % is invalid.".format(name.asString.quote).error;
};

var postUnableToCreateDueToAlreadyExistingModuleError = { |name|
	"unable to create %. module named % already exists".format(name.asString.quote, name.asString.quote).error;
};

var postUnableToCreateDueToInvalidModuleTypeError = { |name, kind|
	"unable to create %. invalid module type %".format(name.asString.quote, kind.asString.quote).error;
};

var postInvalidModuleVisualError = { |module, visualRef|
	var moduleDef = module[\moduleDef];
	var spec = getModuleDefSpec.value(moduleDef);
	var possibleVisualsList = spec[\visuals].collect{ |item| item.asString.quote }.join(", ");
	"invalid visual % for % module named % (possible visuals are %)".format(
		visualRef.asString.quote,
		module[\kind].asString.quote,
		module[\name].asString.quote,
		possibleVisualsList
	).error; // TODO: if no visuals are applicable don't say "possible visuals are ", but "module has no visuals". same with parameters and ins / outs
};

var postInvalidModuleOutputError = { |module, outputRef|
	var moduleDef = module[\moduleDef];
	var spec = getModuleDefSpec.value(moduleDef);
	var possibleOutputsList = spec[\outputs].collect{ |item| item.asString.quote }.join(", ");
	"invalid output % for % module named % (possible outputs are %)".format(
		outputRef.asString.quote,
		module[\kind].asString.quote,
		module[\name].asString.quote,
		possibleOutputsList
	).error;
};

var postInvalidModuleInputError = { |module, inputRef|
	var moduleDef = module[\moduleDef];
	var spec = getModuleDefSpec.value(moduleDef);
	var possibleInputsList = spec[\inputs].collect{ |item| item.asString.quote }.join(", ");
	"invalid input % for % module named % (possible inputs are %)".format(
		inputRef.asString.quote,
		module[\kind].asString.quote,
		module[\name].asString.quote,
		possibleInputsList
	).error;
};

var postModuleNotFoundError = { |moduleRef, modules|
	var moduleList = modules.collect { |module| module[\name].asString }.join(", ");
	"module named % not found among modules %".format(
		moduleRef.asString.quote,
		moduleList.quote
	).error; // TODO: if no modules have been created this still says "among modules    "
};

var postInvalidModuleParameterError = { |module, parameterRef|
	var spec = getModuleDefSpec.value(module[\moduleDef]);

	"parameter % not valid for module named % (kind: % has parameters %)".format(
		parameterRef.asString.quote,
		module[\name].asString.quote,
		module[\kind].asString.quote,
		spec[\parameters].collect { |parameterName| parameterName.asString.quote }.join(", ")
	).error; // TODO: add clarifying array to all other parameter % not valid occurrences
};

/* Standard modules */

var coreModules = [
	( // TODO: make this a singleton
		name: 'SoundIn',
		ugenGraphFunc: {
			|
				out_Left,
				out_Right,
				internal_In
			|

			var in = In.ar(internal_In, 2);
			Out.ar(out_Left, in[0]);
			Out.ar(out_Right, in[1]);
		},
		examples: [
			[
				"Channel reverser",
				nil,
				"Create modules",
				('new' -> ['In', 'SoundIn']),
				('new' -> ['Out', 'SoundOut']),
				nil,
				"Reverse channels",
				('connect' -> ['In/Left', 'Out*Right']),
				('connect' -> ['In/Right', 'Out*Left']),
			]
		],
	),
	( // TODO: make this a singleton
		name: 'SoundOut',
		ugenGraphFunc: {
			|
				in_Left,
				in_Right,
				// TODO param_Gain,
				internal_Out
			|

			var amp = 1; // TODO param_Gain.dbamp;
			Out.ar(internal_Out, [In.ar(in_Left) * amp, In.ar(in_Right) * amp]);
		},
		examples: [
			[
				"Audition a sine oscillator",
				nil,
				"Create modules",
				('new' -> ['Osc', 'SineOsc']),
				('new' -> ['Out', 'SoundOut']),
				nil,
				"Connect modules",
				('connect' -> ['Osc/Out', 'Out*Right']),
				('connect' -> ['Osc/Out', 'Out*Left']),
			]
		],
	/*
		params: [
			'Gain' -> \db.asSpec.copy.maxval_(12).default_(0),
		]
	*/
	)
];

var stdModules = [
	(
		// Status: tested
		name: '44Matrix',
		params: { generateMatrixModulesParams.value(4, 4) },
		ugenGraphFunc: {
			|
				in_In1,
				in_In2,
				in_In3,
				in_In4,
				out_Out1,
				out_Out2,
				out_Out3,
				out_Out4,
				param_FadeTime,
				param_Gate_1_1,
				param_Gate_1_2,
				param_Gate_1_3,
				param_Gate_1_4,
				param_Gate_2_1,
				param_Gate_2_2,
				param_Gate_2_3,
				param_Gate_2_4,
				param_Gate_3_1,
				param_Gate_3_2,
				param_Gate_3_3,
				param_Gate_3_4,
				param_Gate_4_1,
				param_Gate_4_2,
				param_Gate_4_3,
				param_Gate_4_4
			|

			var sigs = [In.ar(in_In1), In.ar(in_In2), In.ar(in_In3), In.ar(in_In4)];

			Out.ar(
				out_Out1,
				(sigs[0] * Lag.kr(param_Gate_1_1, param_FadeTime/1000)) +
				(sigs[1] * Lag.kr(param_Gate_2_1, param_FadeTime/1000)) +
				(sigs[2] * Lag.kr(param_Gate_3_1, param_FadeTime/1000)) +
				(sigs[3] * Lag.kr(param_Gate_4_1, param_FadeTime/1000))
			);

			Out.ar(
				out_Out2,
				(sigs[0] * Lag.kr(param_Gate_1_2, param_FadeTime/1000)) +
				(sigs[1] * Lag.kr(param_Gate_2_2, param_FadeTime/1000)) +
				(sigs[2] * Lag.kr(param_Gate_3_2, param_FadeTime/1000)) +
				(sigs[3] * Lag.kr(param_Gate_4_2, param_FadeTime/1000))
			);

			Out.ar(
				out_Out3,
				(sigs[0] * Lag.kr(param_Gate_1_3, param_FadeTime/1000)) +
				(sigs[1] * Lag.kr(param_Gate_2_3, param_FadeTime/1000)) +
				(sigs[2] * Lag.kr(param_Gate_3_3, param_FadeTime/1000)) +
				(sigs[3] * Lag.kr(param_Gate_4_3, param_FadeTime/1000))
			);

			Out.ar(
				out_Out4,
				(sigs[0] * Lag.kr(param_Gate_1_4, param_FadeTime/1000)) +
				(sigs[1] * Lag.kr(param_Gate_2_4, param_FadeTime/1000)) +
				(sigs[2] * Lag.kr(param_Gate_3_4, param_FadeTime/1000)) +
				(sigs[3] * Lag.kr(param_Gate_4_4, param_FadeTime/1000))
			);
		}
	),
	(
		// Status: tested
		name: '88Matrix',
		params: { generateMatrixModulesParams.value(8, 8) },
		ugenGraphFunc: {
			|
				in_In1,
				in_In2,
				in_In3,
				in_In4,
				in_In5,
				in_In6,
				in_In7,
				in_In8,
				out_Out1,
				out_Out2,
				out_Out3,
				out_Out4,
				out_Out5,
				out_Out6,
				out_Out7,
				out_Out8,
				param_FadeTime,
				param_Gate_1_1,
				param_Gate_1_2,
				param_Gate_1_3,
				param_Gate_1_4,
				param_Gate_1_5,
				param_Gate_1_6,
				param_Gate_1_7,
				param_Gate_1_8,
				param_Gate_2_1,
				param_Gate_2_2,
				param_Gate_2_3,
				param_Gate_2_4,
				param_Gate_2_5,
				param_Gate_2_6,
				param_Gate_2_7,
				param_Gate_2_8,
				param_Gate_3_1,
				param_Gate_3_2,
				param_Gate_3_3,
				param_Gate_3_4,
				param_Gate_3_5,
				param_Gate_3_6,
				param_Gate_3_7,
				param_Gate_3_8,
				param_Gate_4_1,
				param_Gate_4_2,
				param_Gate_4_3,
				param_Gate_4_4,
				param_Gate_4_5,
				param_Gate_4_6,
				param_Gate_4_7,
				param_Gate_4_8,
				param_Gate_5_1,
				param_Gate_5_2,
				param_Gate_5_3,
				param_Gate_5_4,
				param_Gate_5_5,
				param_Gate_5_6,
				param_Gate_5_7,
				param_Gate_5_8,
				param_Gate_6_1,
				param_Gate_6_2,
				param_Gate_6_3,
				param_Gate_6_4,
				param_Gate_6_5,
				param_Gate_6_6,
				param_Gate_6_7,
				param_Gate_6_8,
				param_Gate_7_1,
				param_Gate_7_2,
				param_Gate_7_3,
				param_Gate_7_4,
				param_Gate_7_5,
				param_Gate_7_6,
				param_Gate_7_7,
				param_Gate_7_8,
				param_Gate_8_1,
				param_Gate_8_2,
				param_Gate_8_3,
				param_Gate_8_4,
				param_Gate_8_5,
				param_Gate_8_6,
				param_Gate_8_7,
				param_Gate_8_8
			|

			var sigs = [In.ar(in_In1), In.ar(in_In2), In.ar(in_In3), In.ar(in_In4), In.ar(in_In5), In.ar(in_In6), In.ar(in_In7), In.ar(in_In8)];

			Out.ar(
				out_Out1,
				(sigs[0] * Lag.kr(param_Gate_1_1, param_FadeTime/1000)) +
				(sigs[1] * Lag.kr(param_Gate_2_1, param_FadeTime/1000)) +
				(sigs[2] * Lag.kr(param_Gate_3_1, param_FadeTime/1000)) +
				(sigs[3] * Lag.kr(param_Gate_4_1, param_FadeTime/1000)) +
				(sigs[4] * Lag.kr(param_Gate_5_1, param_FadeTime/1000)) +
				(sigs[5] * Lag.kr(param_Gate_6_1, param_FadeTime/1000)) +
				(sigs[6] * Lag.kr(param_Gate_7_1, param_FadeTime/1000)) +
				(sigs[7] * Lag.kr(param_Gate_8_1, param_FadeTime/1000))
			);

			Out.ar(
				out_Out2,
				(sigs[0] * Lag.kr(param_Gate_1_2, param_FadeTime/1000)) +
				(sigs[1] * Lag.kr(param_Gate_2_2, param_FadeTime/1000)) +
				(sigs[2] * Lag.kr(param_Gate_3_2, param_FadeTime/1000)) +
				(sigs[3] * Lag.kr(param_Gate_4_2, param_FadeTime/1000)) +
				(sigs[4] * Lag.kr(param_Gate_5_2, param_FadeTime/1000)) +
				(sigs[5] * Lag.kr(param_Gate_6_2, param_FadeTime/1000)) +
				(sigs[6] * Lag.kr(param_Gate_7_2, param_FadeTime/1000)) +
				(sigs[7] * Lag.kr(param_Gate_8_2, param_FadeTime/1000))
			);

			Out.ar(
				out_Out3,
				(sigs[0] * Lag.kr(param_Gate_1_3, param_FadeTime/1000)) +
				(sigs[1] * Lag.kr(param_Gate_2_3, param_FadeTime/1000)) +
				(sigs[2] * Lag.kr(param_Gate_3_3, param_FadeTime/1000)) +
				(sigs[3] * Lag.kr(param_Gate_4_3, param_FadeTime/1000)) +
				(sigs[4] * Lag.kr(param_Gate_5_3, param_FadeTime/1000)) +
				(sigs[5] * Lag.kr(param_Gate_6_3, param_FadeTime/1000)) +
				(sigs[6] * Lag.kr(param_Gate_7_3, param_FadeTime/1000)) +
				(sigs[7] * Lag.kr(param_Gate_8_3, param_FadeTime/1000))
			);

			Out.ar(
				out_Out4,
				(sigs[0] * Lag.kr(param_Gate_1_4, param_FadeTime/1000)) +
				(sigs[1] * Lag.kr(param_Gate_2_4, param_FadeTime/1000)) +
				(sigs[2] * Lag.kr(param_Gate_3_4, param_FadeTime/1000)) +
				(sigs[3] * Lag.kr(param_Gate_4_4, param_FadeTime/1000)) +
				(sigs[4] * Lag.kr(param_Gate_5_4, param_FadeTime/1000)) +
				(sigs[5] * Lag.kr(param_Gate_6_4, param_FadeTime/1000)) +
				(sigs[6] * Lag.kr(param_Gate_7_4, param_FadeTime/1000)) +
				(sigs[7] * Lag.kr(param_Gate_8_4, param_FadeTime/1000))
			);

			Out.ar(
				out_Out5,
				(sigs[0] * Lag.kr(param_Gate_1_5, param_FadeTime/1000)) +
				(sigs[1] * Lag.kr(param_Gate_2_5, param_FadeTime/1000)) +
				(sigs[2] * Lag.kr(param_Gate_3_5, param_FadeTime/1000)) +
				(sigs[3] * Lag.kr(param_Gate_4_5, param_FadeTime/1000)) +
				(sigs[4] * Lag.kr(param_Gate_5_5, param_FadeTime/1000)) +
				(sigs[5] * Lag.kr(param_Gate_6_5, param_FadeTime/1000)) +
				(sigs[6] * Lag.kr(param_Gate_7_5, param_FadeTime/1000)) +
				(sigs[7] * Lag.kr(param_Gate_8_5, param_FadeTime/1000))
			);

			Out.ar(
				out_Out6,
				(sigs[0] * Lag.kr(param_Gate_1_6, param_FadeTime/1000)) +
				(sigs[1] * Lag.kr(param_Gate_2_6, param_FadeTime/1000)) +
				(sigs[2] * Lag.kr(param_Gate_3_6, param_FadeTime/1000)) +
				(sigs[3] * Lag.kr(param_Gate_4_6, param_FadeTime/1000)) +
				(sigs[4] * Lag.kr(param_Gate_5_6, param_FadeTime/1000)) +
				(sigs[5] * Lag.kr(param_Gate_6_6, param_FadeTime/1000)) +
				(sigs[6] * Lag.kr(param_Gate_7_6, param_FadeTime/1000)) +
				(sigs[7] * Lag.kr(param_Gate_8_6, param_FadeTime/1000))
			);

			Out.ar(
				out_Out7,
				(sigs[0] * Lag.kr(param_Gate_1_7, param_FadeTime/1000)) +
				(sigs[1] * Lag.kr(param_Gate_2_7, param_FadeTime/1000)) +
				(sigs[2] * Lag.kr(param_Gate_3_7, param_FadeTime/1000)) +
				(sigs[3] * Lag.kr(param_Gate_4_7, param_FadeTime/1000)) +
				(sigs[4] * Lag.kr(param_Gate_5_7, param_FadeTime/1000)) +
				(sigs[5] * Lag.kr(param_Gate_6_7, param_FadeTime/1000)) +
				(sigs[6] * Lag.kr(param_Gate_7_7, param_FadeTime/1000)) +
				(sigs[7] * Lag.kr(param_Gate_8_7, param_FadeTime/1000))
			);

			Out.ar(
				out_Out8,
				(sigs[0] * Lag.kr(param_Gate_1_8, param_FadeTime/1000)) +
				(sigs[1] * Lag.kr(param_Gate_2_8, param_FadeTime/1000)) +
				(sigs[2] * Lag.kr(param_Gate_3_8, param_FadeTime/1000)) +
				(sigs[3] * Lag.kr(param_Gate_4_8, param_FadeTime/1000)) +
				(sigs[4] * Lag.kr(param_Gate_5_8, param_FadeTime/1000)) +
				(sigs[5] * Lag.kr(param_Gate_6_8, param_FadeTime/1000)) +
				(sigs[6] * Lag.kr(param_Gate_7_8, param_FadeTime/1000)) +
				(sigs[7] * Lag.kr(param_Gate_8_8, param_FadeTime/1000))
			);

		}
	),
	(
		// Status: tested
		// Inspiration from A-140
		// TODO: is it possible to implement Retrig(?)
		name: 'ADSREnv',
		params: [
			'Attack' -> (
				Spec: ControlSpec(0.1, 2000, 'exp', 0, 5, "ms"),
				LagTime: 0.1
			),
			'Decay' -> (
				Spec: ControlSpec(0.1, 8000, 'exp', 0, 200, "ms"),
				LagTime: 0.1
			),
			'Sustain' -> (
				Spec: ControlSpec(0, 1, 'lin', 0, 0.5, ""),
				LagTime: 0.1
			),
			'Release' -> (
				Spec: ControlSpec(0.1, 8000, 'exp', 0, 200, "ms"),
				LagTime: 0.1
			),
			'Gate' -> ControlSpec(0, 1, step: 1, default: 0) // TODO: DRY the gate/reset/boolean specs
//			'Curve' -> ControlSpec(-10, 10, 'lin', -4), TODO
		],
		ugenGraphFunc: {
			|
				in_Gate,
				// TODO: in_Retrig,
				out_Out,
				// TODO: out_OutInverse,
				param_Attack,
				param_Decay,
				param_Sustain,
				param_Release,
				param_Gate/*,
				param_Curve TODO */
			|

			var sig_Gate = In.ar(in_Gate); // TODO: gate threshold on A-148 is 3V = 0.3
			var curve = -4; // TODO: default is -4, exp approximation -13.81523 !?
			Out.ar(
				out_Out,
				EnvGen.ar(
					Env.adsr(param_Attack/1000, param_Decay/1000, param_Sustain, param_Release/1000, curve: curve),
					// TODO ((sig_Gate > 0) + (param_Gate > 0)) > 0,
					((sig_Gate > 0) + (K2A.ar(param_Gate) > 0)) > 0, // TODO: Is K2A really needed?
					levelScale: 0.8 // TODO: ~ 8 V
				)
			);
		}
	),
	(
		// status: untested
		// TODO: This is ADSREnv with Retrig input for testing
		name: 'ADSREnv2',
		params: [
			'Attack' -> (
				Spec: ControlSpec(0.1, 2000, 'exp', 0, 5, "ms"),
				LagTime: 0.1
			),
			'Decay' -> (
				Spec: ControlSpec(0.1, 8000, 'exp', 0, 200, "ms"),
				LagTime: 0.1
			),
			'Sustain' -> (
				Spec: ControlSpec(0, 1, 'lin', 0, 0.5, ""),
				LagTime: 0.1
			),
			'Release' -> (
				Spec: ControlSpec(0.1, 8000, 'exp', 0, 200, "ms"),
				LagTime: 0.1
			)
//			'Curve' -> ControlSpec(-10, 10, 'lin', -4), TODO
		],
		ugenGraphFunc: {
			|
				in_Gate,
				in_Retrig,
				out_Out,
				// TODO: out_OutInverse,
				param_Attack,
				param_Decay,
				param_Sustain,
				param_Release
				/* param_Curve TODO */
			|

			var sig_Gate = In.ar(in_Gate);
			var sig_Retrig = In.ar(in_Retrig);
			var curve = -4; // TODO: default is -4, exp approximation -13.81523 !?

			var gate = (sig_Gate > 0) + ((-1)*Trig1.ar(sig_Retrig, 1/SampleRate.ir));
			Out.ar(
				out_Out,
				EnvGen.ar(
					Env.adsr(param_Attack/1000, param_Decay/1000, param_Sustain, param_Release/1000, curve: curve),
					// TODO ((sig_Gate > 0) + (param_Gate > 0)) > 0,
					// ((sig_Gate > 0) + (K2A.ar(param_Gate) > 0)) > 0,
					gate,
					levelScale: 0.8 // TODO: ~ 8 V
				)
			);
		}
	),
	(
		// Status: tested
		// TODO: test Exp input more
		name: 'Amp',
		params: [
			'Level' -> (
				Spec: \unipolar.asSpec,
				LagTime: 0.1
			)
		],
		ugenGraphFunc: {
			|
				in_Exp,
				in_Lin,
				in_In,
				out_Out,
				param_Level
			|

			var sig_Exp = In.ar(in_Exp);
			var sig_Lin = In.ar(in_Lin);
			var sig_In = In.ar(in_In);

			var curveSpec = ControlSpec.new(0, 1, 13.81523); // TODO: exp approximation, dunno about this?

			Out.ar(
				out_Out,
				sig_In * (param_Level + sig_Lin.clip(0, 0.5) + curveSpec.map(sig_Exp).clip(0, 0.5)).clip(0, 0.5)
			);
		}
	),
	(
		// Status: partly tested, exp mode needs more testing
		// Inspiration from A-130/A-131
		name: 'Amp2',
		params: [
			'Gain' -> (
				Spec: \unipolar.asSpec,
				LagTime: 0.1
			),
			'GainModulation' -> (
				Spec: \bipolar.asSpec,
				LagTime: 0.1
			),
			'In1' -> (
				Spec: \unipolar.asSpec,
				LagTime: 0.1
			),
			'In2' -> (
				Spec: \unipolar.asSpec,
				LagTime: 0.1
			),
			'Out' -> (
				Spec: \unipolar.asSpec,
				LagTime: 0.1
			),
			'Mode' -> ControlSpec.new(0, 1, 'lin', 1, 0),
		],
		ugenGraphFunc: {
			|
				in_GainModulation,
				in_In1,
				in_In2,
				out_Out,
				param_Gain,
				param_GainModulation,
				param_In1,
				param_In2,
				param_Out,
				param_Mode
			|

			var sig_In1 = In.ar(in_In1);
			var sig_In2 = In.ar(in_In2);
			var sig_GainModulation = In.ar(in_GainModulation); // TODO: bipolar unmap

			var curveSpec = ControlSpec.new(0, 1, 13.81523); // TODO: exp approximation, dunno about this?

			var gainGain = SelectX.kr(param_Mode, [param_Gain, curveSpec.map(param_Gain)]); // TODO: exp hack
			var in1Gain = SelectX.kr(param_Mode, [param_In1, curveSpec.map(param_In1)]); // TODO: exp hack
			var in2Gain = SelectX.kr(param_Mode, [param_In2, curveSpec.map(param_In2)]); // TODO: exp hack
			var outGain = SelectX.kr(param_Mode, [param_Out, curveSpec.map(param_Out)]); // TODO: exp hack

			var inMix = (sig_In1 * in1Gain) + (sig_In2 * in2Gain);

			Out.ar(
				out_Out,
				inMix * (gainGain + (sig_GainModulation * param_GainModulation)) * outGain
			);
		}
	),
	(
		// Status: tested
		name: 'BPFilter',
		params: [
			'AudioLevel' -> (
				Spec: \amp.asSpec.copy.default_(1), // TODO: updated
				LagTime: 0.1
			),
			'Frequency' -> (
				Spec: \widefreq.asSpec,
				LagTime: 0.1
			),
			'Resonance' -> (
				Spec: \unipolar.asSpec,
				LagTime: 0.1
			),
			'FM' -> (
				Spec: \bipolar.asSpec,
				LagTime: 0.1
			),
			'ResonanceModulation' -> (
				Spec: \bipolar.asSpec,
				LagTime: 0.1
			),
		],
		ugenGraphFunc: {
			|
				in_In,
				in_FM,
				in_ResonanceModulation,
				out_Out,
				param_AudioLevel,
				param_Frequency,
				param_Resonance,
				param_FM,
				param_ResonanceModulation
			|

			var sig_In = In.ar(in_In);
			var sig_FM = In.ar(in_FM);
			var sig_ResonanceModulation = In.ar(in_ResonanceModulation);

			var frequencySpec = \widefreq.asSpec;
			var resonanceSpec = \unipolar.asSpec;

			var sig_In_Atten = sig_In * param_AudioLevel;
			var frequency = frequencySpec.map(frequencySpec.unmap(param_Frequency) + (sig_FM * param_FM));
			var resonance = resonanceSpec.map(resonanceSpec.unmap(param_Resonance) + (sig_ResonanceModulation * param_ResonanceModulation));

			Out.ar(
				out_Out,
				SVF.ar(
					sig_In_Atten,
					frequency,
					resonance,
					lowpass: 0,
					bandpass: 1,
					highpass: 0,
					notch: 0,
					peak: 0
				)
			);
		}
	),
	(
		// Status: tested
		name: 'BRFilter',
		params: [
			'AudioLevel' -> (
				Spec: \amp.asSpec.copy.default_(1), // TODO: updated
				LagTime: 0.1
			),
			'Frequency' -> (
				Spec: \widefreq.asSpec,
				LagTime: 0.1
			),
			'Resonance' -> (
				Spec: \unipolar.asSpec,
				LagTime: 0.1
			),
			'FM' -> (
				Spec: \bipolar.asSpec,
				LagTime: 0.1
			),
			'ResonanceModulation' -> (
				Spec: \bipolar.asSpec,
				LagTime: 0.1
			),
		],
		ugenGraphFunc: {
			|
				in_In,
				in_FM,
				in_ResonanceModulation,
				out_Out,
				param_AudioLevel,
				param_Frequency,
				param_Resonance,
				param_FM,
				param_ResonanceModulation
			|

			var sig_In = In.ar(in_In);
			var sig_FM = In.ar(in_FM);
			var sig_ResonanceModulation = In.ar(in_ResonanceModulation);

			var frequencySpec = \widefreq.asSpec;
			var resonanceSpec = \unipolar.asSpec;

			var sig_In_Atten = sig_In * param_AudioLevel;
			var frequency = frequencySpec.map(frequencySpec.unmap(param_Frequency) + (sig_FM * param_FM));
			var resonance = resonanceSpec.map(resonanceSpec.unmap(param_Resonance) + (sig_ResonanceModulation * param_ResonanceModulation));

			Out.ar(
				out_Out,
				SVF.ar(
					sig_In_Atten,
					frequency,
					resonance,
					lowpass: 0,
					bandpass: 0,
					highpass: 0,
					notch: 1,
					peak: 0
				)
			);
		}
	),
	(
		name: 'Comp2',
		params: [
			'Threshold' -> \db.asSpec.copy.default_(-10),
			'Attack' -> ControlSpec(0.1, 250, 'exp', 0, 10, "ms"),
			'Release' -> ControlSpec(0.1, 1000, 'exp', 0, 100, "ms"),
			'Ratio' -> ControlSpec(0, 20, default: 3),
			'MakeUp' -> \db.asSpec.copy.maxval_(20).default_(0)
		],
		ugenGraphFunc: { |
				param_Threshold,
				param_Attack,
				param_Release,
				param_Ratio,
				param_MakeUp,
				in_Left,
				in_Right,
				in_SideChain,
				connectedin_SideChain,
				out_Left,
				out_Right,
				visual_GR
			|
			var sig_Left = In.ar(in_Left, 1);
			var sig_Right = In.ar(in_Right, 1);

			var sig_dc = DC.ar(1);

			var control = (sig_Left + sig_Right) / 2; // TODO: possibly insert external side chain here
			// TODO: possibly insert sidechain HPF filter here
			var compressed = Compander.ar(
				[sig_Left, sig_Right, sig_dc],
				control,
				param_Threshold.dbamp,
				slopeAbove: 1/param_Ratio,
				clampTime: param_Attack/1000,
				relaxTime: param_Release/1000
			);

			Out.ar(out_Left, compressed[0] * param_MakeUp.dbamp);
			Out.ar(out_Right, compressed[1] * param_MakeUp.dbamp);
			Out.kr(visual_GR, compressed[2].ampdb);
		}
	),
	(
		// Status: untested
		name: 'DbMixer',
		params: [
			'In1' -> (
				Spec: \db.asSpec,
				LagTime: 0
			),
			'In2' -> (
				Spec: \db.asSpec,
				LagTime: 0
			),
			'In3' -> (
				Spec: \db.asSpec,
				LagTime: 0
			),
			'In4' -> (
				Spec: \db.asSpec,
				LagTime: 0
			),
			'Out' -> (
				Spec: \db.asSpec,
				LagTime: 0
			)
		],
		ugenGraphFunc: {
			|
				in_In1,
				in_In2,
				in_In3,
				in_In4,
				out_Out,
				param_In1,
				param_In2,
				param_In3,
				param_In4,
				param_Out
			|

			var sig_In1 = In.ar(in_In1); // TODO: Add lag here instead
			var sig_In2 = In.ar(in_In2);
			var sig_In3 = In.ar(in_In3);
			var sig_In4 = In.ar(in_In4);

			Out.ar(
				out_Out,
				(
					(sig_In1 * param_In1.dbamp) +
					(sig_In2 * param_In2.dbamp) +
					(sig_In3 * param_In3.dbamp) +
					(sig_In4 * param_In4.dbamp)
				) * param_Out.dbamp
			);
		}
	),
	(
		// Status: partly tested. TODO: what modulation input range should be used?
		name: 'Delay',
		params: [
			'DelayTime' -> (
				Spec: ControlSpec(0.1, 5000, 'exp', 0, 300, "ms"),
				LagTime: 0.25
			),
			'DelayTimeModulation' -> (
				Spec: \bipolar.asSpec,
				LagTime: 0.1
			),
		],
		ugenGraphFunc: {
			|
				in_In,
				in_DelayTimeModulation,
				out_Out,
				param_DelayTime,
				param_DelayTimeModulation
			|

			var sig_In = In.ar(in_In);
			var sig_DelayTimeModulation = In.ar(in_DelayTimeModulation);

			var delayTimeSpec = ControlSpec(0.1, 5000, 'exp', 0, 300, "ms");

			var delayTimeMs = delayTimeSpec.map(
				delayTimeSpec.unmap(param_DelayTime) + (sig_DelayTimeModulation * param_DelayTimeModulation)
			);

			var delayed = DelayC.ar(sig_In, maxdelaytime: delayTimeSpec.maxval/1000, delaytime: delayTimeMs/1000); // TODO: ControlDur.ir minimum

			Out.ar(out_Out, delayed);
		}
	),
	(
		name: 'EnvF',
		params: [
/*
			'Attack' -> (
				Spec: ControlSpec(0.1, 2000, 'exp', 0, 100, "ms"),
				LagTime: 0.1
			),
			'Decay' -> (
				Spec: ControlSpec(0.1, 8000, 'exp', 0, 200, "ms"),
				LagTime: 0.1
			),
*/
			'Attack' -> ControlSpec(0.1, 2000, 'exp', 0, 100, "ms"),
			'Decay' -> ControlSpec(0.1, 8000, 'exp', 0, 200, "ms"),
			'Sensitivity' -> ControlSpec(0, 1, default: 0.5),
			'Threshold' -> ControlSpec(0, 1, default: 0.5)
		],
		ugenGraphFunc: { |
				param_Attack,
				param_Decay,
				param_Sensitivity,
				param_Threshold,
				in_In,
				out_Env,
				out_Gate
			|
			var sig_In = In.ar(in_In, 1);

			var env = Lag3UD.ar(abs(sig_In), param_Attack/1000, param_Decay/1000) * 5 * param_Sensitivity; // TODO: Tryout Amplitude ugen instead

			Out.ar(out_Env, env);
			Out.ar(out_Gate, Trig1.ar(abs(sig_In) > param_Threshold));
		}
	),
	(
		// Status: not tested
		// TODO: Fix parameter names
		name: 'FMVoice',
		params: {
			var numOscs = 3;
			var params = [
				'Freq' -> \freq.asSpec,
				'Timbre' -> ControlSpec(0, 5, 'lin', nil, 1, "")
			];

			numOscs.do { |oscnum|
				params = params.addAll(
					[
						"Osc%Gain".format(oscnum+1) -> \amp.asSpec,
						"Osc%Partial".format(oscnum+1) -> ControlSpec(0.5, 12, 'lin', 0.5, 1, ""),
						"Osc%Fixed".format(oscnum+1) -> ControlSpec(0, 1, 'lin', 1, 0, ""),
						"Osc%Fixedfreq".format(oscnum+1) -> \widefreq.asSpec,
						"Osc%Index".format(oscnum+1) -> ControlSpec(0, 24, 'lin', 0, 3, ""),
						"Osc%Outlevel".format(oscnum+1) -> \amp.asSpec,
						"Mod_To_Osc%Freq".format(oscnum+1) -> \bipolar.asSpec,
						"Mod_To_Osc%Gain".format(oscnum+1) -> \bipolar.asSpec,
					]
				);

				numOscs.do { |dest|
					params = params.add(
						"Osc%_To_Osc%Freq".format(oscnum+1, dest+1) -> \amp.asSpec
					);
				};
			};

			params.collect { |assoc|
				assoc.key.asSymbol -> assoc.value
			};
		},
		ugenGraphFunc: {
			|
				in_Modulation,
				out_Out,
				param_Freq, // TODO: Frequency
				param_Timbre,
				param_Osc1Gain,
				param_Osc1Partial,
				param_Osc1Fixed,
				param_Osc1Fixedfreq,
				param_Osc1Index,
				param_Osc1Outlevel,
				param_Osc1_To_Osc1Freq,
				param_Osc1_To_Osc2Freq,
				param_Osc1_To_Osc3Freq,
				param_Osc2Gain,
				param_Osc2Partial,
				param_Osc2Fixed,
				param_Osc2Fixedfreq,
				param_Osc2Index,
				param_Osc2Outlevel,
				param_Osc2_To_Osc1Freq,
				param_Osc2_To_Osc2Freq,
				param_Osc2_To_Osc3Freq,
				param_Osc3Gain,
				param_Osc3Partial,
				param_Osc3Fixed,
				param_Osc3Fixedfreq,
				param_Osc3Index,
				param_Osc3Outlevel,
				param_Osc3_To_Osc3Freq,
				param_Osc3_To_Osc2Freq,
				param_Osc3_To_Osc1Freq,
				param_Mod_To_Osc1Gain,
				param_Mod_To_Osc2Gain,
				param_Mod_To_Osc3Gain,
				param_Mod_To_Osc1Freq,
				param_Mod_To_Osc2Freq,
				param_Mod_To_Osc3Freq
			|

			var sig;

			var osc1, osc2, osc3;
			var osc1freq, osc2freq, osc3freq;
			var osc1freqbasemod, osc2freqbasemod, osc3freqbasemod;
			var oscfeedback = LocalIn.ar(3);
			var sig_Modulation = In.ar(in_Modulation);

			osc1freq = Select.kr(param_Osc1Fixed, [param_Freq*param_Osc1Partial, param_Osc1Fixedfreq]);
			osc2freq = Select.kr(param_Osc2Fixed, [param_Freq*param_Osc2Partial, param_Osc2Fixedfreq]);
			osc3freq = Select.kr(param_Osc3Fixed, [param_Freq*param_Osc3Partial, param_Osc3Fixedfreq]);

			osc1freqbasemod = param_Osc1Index * osc1freq * param_Timbre;
			osc2freqbasemod = param_Osc2Index * osc2freq * param_Timbre;
			osc3freqbasemod = param_Osc3Index * osc3freq * param_Timbre;

			osc1 = SinOsc.ar(
				osc1freq
					+ (osc1freqbasemod * oscfeedback[0] * param_Osc1_To_Osc1Freq)
					+ (osc1freqbasemod * oscfeedback[1] * param_Osc2_To_Osc1Freq)
					+ (osc1freqbasemod * oscfeedback[2] * param_Osc3_To_Osc1Freq)
					+ (osc1freqbasemod * sig_Modulation * param_Mod_To_Osc1Freq)
			) * (param_Osc1Gain + (param_Mod_To_Osc1Gain * sig_Modulation));

			osc2 = SinOsc.ar(
				osc2freq
					+ (osc2freqbasemod * osc1 * param_Osc1_To_Osc2Freq)
					+ (osc2freqbasemod * oscfeedback[1] * param_Osc2_To_Osc2Freq)
					+ (osc2freqbasemod * oscfeedback[2] * param_Osc3_To_Osc2Freq)
					+ (osc2freqbasemod * sig_Modulation * param_Mod_To_Osc2Freq)
			) * (param_Osc2Gain + (param_Mod_To_Osc2Gain * sig_Modulation));

			osc3 = SinOsc.ar(
				osc3freq
					+ (osc3freqbasemod * osc1 * param_Osc1_To_Osc3Freq)
					+ (osc3freqbasemod * osc2 * param_Osc2_To_Osc3Freq)
					+ (osc3freqbasemod * oscfeedback[2] * param_Osc3_To_Osc3Freq)
					+ (osc3freqbasemod * sig_Modulation * param_Mod_To_Osc3Freq)
			) * (param_Osc3Gain + (param_Mod_To_Osc3Gain * sig_Modulation));

			sig = (osc1 * param_Osc1Outlevel) + (osc2 * param_Osc2Outlevel) + (osc3 * param_Osc3Outlevel);

			LocalOut.ar([osc1, osc2, osc3]);
			Out.ar(out_Out, sig);
		}
	),
	(
		// Status: tested
		name: 'FreqGate',
		params: [
			'Frequency' -> \freq.asSpec,
			'Gate' -> ControlSpec(0, 1, step: 1, default: 0) // TODO: DRY the gate/reset/boolean specs
		],
		ugenGraphFunc: {
			|
				out_Frequency,
				out_Gate,
				out_Trig,
				param_Frequency,
				param_Gate
			|

			var sig_Gate = K2A.ar(param_Gate);
			var octs = ((param_Frequency.cpsoct-3)/10).clip(-0.5, 0.5); // 0.1 = 1 oct
			Out.ar(out_Frequency, K2A.ar(octs));
			Out.ar(out_Gate, sig_Gate);
			Out.ar(out_Trig, Trig.ar(sig_Gate, 1/SampleRate.ir)); // TODO: too short a trig? Do the 1/60 thing?
		}
	),
	(
		// Status: partly tested. TODO: review modulation input mapping
		name: 'FShift',
		params: [
			'Frequency' -> (
				Spec: ControlSpec(-2000, 2000, 'lin', 0, 0, "Hz"),
				LagTime: 0.1
			),
			'FM' -> (
				Spec: \bipolar.asSpec,
				LagTime: 0.1
			),
		],
		ugenGraphFunc: {
			|
				in_Left,
				in_Right,
				in_FM,
				out_Left,
				out_Right,
				param_Frequency,
				param_FM
			|

			var frequencySpec = ControlSpec(-2000, 2000, 'lin', 0, 0, "Hz");

			var sig_Left = In.ar(in_Left);
			var sig_Right = In.ar(in_Right);
			var sig_FM = In.ar(in_FM);

			var shifted = FreqShift.ar(
				[sig_Left, sig_Right],
				frequencySpec.constrain(param_Frequency + (sig_FM * 2000 * param_FM))
			);

			Out.ar(out_Left, shifted[0]);
			Out.ar(out_Right, shifted[1]);
		}
	),
	(
		// Status: tested
		name: 'HPFilter',
		params: [
			'AudioLevel' -> (
				Spec: \amp.asSpec.copy.default_(1), // TODO: updated
				LagTime: 0.1
			),
			'Frequency' -> (
				Spec: \widefreq.asSpec,
				LagTime: 0.1
			),
			'Resonance' -> (
				Spec: \unipolar.asSpec,
				LagTime: 0.1
			),
			'FM' -> (
				Spec: \bipolar.asSpec,
				LagTime: 0.1
			),
			'ResonanceModulation' -> (
				Spec: \bipolar.asSpec,
				LagTime: 0.1
			),
		],
		ugenGraphFunc: {
			|
				in_In,
				in_FM,
				in_ResonanceModulation,
				out_Out,
				param_AudioLevel,
				param_Frequency,
				param_Resonance,
				param_FM,
				param_ResonanceModulation
			|

			var sig_In = In.ar(in_In);
			var sig_FM = In.ar(in_FM);
			var sig_ResonanceModulation = In.ar(in_ResonanceModulation);

			var frequencySpec = \widefreq.asSpec;
			var resonanceSpec = \unipolar.asSpec;

			var sig_In_Atten = sig_In * param_AudioLevel;
			var frequency = frequencySpec.map(frequencySpec.unmap(param_Frequency) + (sig_FM * param_FM));
			var resonance = resonanceSpec.map(resonanceSpec.unmap(param_Resonance) + (sig_ResonanceModulation * param_ResonanceModulation));

			Out.ar(
				out_Out,
				SVF.ar(
					sig_In_Atten,
					frequency,
					resonance,
					lowpass: 0,
					bandpass: 0,
					highpass: 1,
					notch: 0,
					peak: 0
				)
			);
		}
	),
/*
	(
		name: 'Limit2',
		params: [
			'Threshold' -> \db.asSpec.copy.default_(-10),
			'Attack' -> ControlSpec(0.1, 250, 'exp', 0, 10, "ms"),
			'Release' -> ControlSpec(0.1, 1000, 'exp', 0, 100, "ms"),
			'Ratio' -> ControlSpec(0, 20, default: 3),
			'MakeUp' -> \db.asSpec.copy.maxval_(20).default_(0)
		],
		ugenGraphFunc: { |
				param_Threshold,
				param_Attack,
				param_Release,
				param_Ratio,
				param_MakeUp,
				in_Left,
				in_Right,
				in_SideChain,
				connectedin_SideChain,
				out_Left,
				out_Right,
				visual_GR
			|
			var sig_Left = In.ar(in_Left, 1);
			var sig_Right = In.ar(in_Right, 1);

			var sig_dc = DC.ar(1);

			var control = (sig_Left + sig_Right) / 2; // TODO: possibly insert external side chain here
			// TODO: possibly insert sidechain HPF filter here
			var compressed = Compander.ar(
				[sig_Left, sig_Right, sig_dc],
				control,
				param_Threshold.dbamp,
				slopeAbove: 1/param_Ratio,
				clampTime: param_Attack/1000,
				relaxTime: param_Release/1000
			);

			Out.ar(out_Left, compressed[0] * param_MakeUp.dbamp);
			Out.ar(out_Right, compressed[1] * param_MakeUp.dbamp);
			Out.kr(visual_GR, compressed[2].ampdb);
		}
	),
*/
	(
		// Status: tested
		name: 'LinMixer',
		params: [
			'In1' -> (
				Spec: \unipolar.asSpec, // TODO: maxval 4?
				LagTime: 0.1
			),
			'In2' -> (
				Spec: \unipolar.asSpec,
				LagTime: 0.1
			),
			'In3' -> (
				Spec: \unipolar.asSpec,
				LagTime: 0.1
			),
			'In4' -> (
				Spec: \unipolar.asSpec,
				LagTime: 0.1
			),
			'Out' -> ( // TODO: 0 is default, is that right?
				Spec: \unipolar.asSpec,
				LagTime: 0.1
			)
		],
		ugenGraphFunc: {
			|
				in_In1,
				in_In2,
				in_In3,
				in_In4,
				out_Out,
				param_In1,
				param_In2,
				param_In3,
				param_In4,
				param_Out
			|

			var sig_In1 = In.ar(in_In1);
			var sig_In2 = In.ar(in_In2);
			var sig_In3 = In.ar(in_In3);
			var sig_In4 = In.ar(in_In4);

			Out.ar(
				out_Out,
				(
					(sig_In1 * param_In1) +
					(sig_In2 * param_In2) +
					(sig_In3 * param_In3) +
					(sig_In4 * param_In4)
				) * param_Out
			);
		}
	),
	(
		// Status: tested
		name: 'LPFilter',
		params: [
			'AudioLevel' -> (
				Spec: \amp.asSpec.copy.default_(1), // TODO: updated
				LagTime: 0.1
			),
			'Frequency' -> (
				Spec: \widefreq.asSpec,
				LagTime: 0.1
			),
			'Resonance' -> (
				Spec: \unipolar.asSpec,
				LagTime: 0.1
			),
			'FM' -> (
				Spec: \bipolar.asSpec,
				LagTime: 0.1
			),
			'ResonanceModulation' -> (
				Spec: \bipolar.asSpec,
				LagTime: 0.1
			),
		],
		ugenGraphFunc: {
			|
				in_In,
				in_FM,
				in_ResonanceModulation,
				out_Out,
				param_AudioLevel,
				param_Frequency,
				param_Resonance,
				param_FM,
				param_ResonanceModulation
			|

			var sig_In = In.ar(in_In);
			var sig_FM = In.ar(in_FM);
			var sig_ResonanceModulation = In.ar(in_ResonanceModulation);

			var frequencySpec = \widefreq.asSpec;
			var resonanceSpec = \unipolar.asSpec;

			var sig_In_Atten = sig_In * param_AudioLevel;
			var frequency = frequencySpec.map(frequencySpec.unmap(param_Frequency) + (sig_FM * param_FM));
			var resonance = resonanceSpec.map(resonanceSpec.unmap(param_Resonance) + (sig_ResonanceModulation * param_ResonanceModulation));

			Out.ar(
				out_Out,
				SVF.ar(
					sig_In_Atten,
					frequency,
					resonance,
					lowpass: 1,
					bandpass: 0,
					highpass: 0,
					notch: 0,
					peak: 0
				)
			);
		}
	),
	(
		// Status: tested
		name: 'LPLadder',
		params: [
			'Frequency' -> (
				Spec: \widefreq.asSpec,
				LagTime: 0.1
			),
			'Resonance' -> (
				Spec: \unipolar.asSpec,
				LagTime: 0.1
			),
			'FM' -> (
				Spec: \bipolar.asSpec,
				LagTime: 0.1
			),
			'ResonanceModulation' -> (
				Spec: \bipolar.asSpec,
				LagTime: 0.1
			),
		],
		visuals: [
			'Frequency' -> (
				Spec: \widefreq.asSpec,
			),
		],
		ugenGraphFunc: {
			|
				in_In,
				in_FM,
				in_ResonanceModulation,
				out_Out,
				param_Frequency,
				param_Resonance,
				param_FM,
				param_ResonanceModulation,
				visual_Frequency
			|

			var sig_In = In.ar(in_In);
			var sig_FM = In.ar(in_FM);
			var sig_ResonanceModulation = In.ar(in_ResonanceModulation);

			var frequencySpec = \widefreq.asSpec;
			var resonanceSpec = \unipolar.asSpec;
			var frequency = frequencySpec.map(frequencySpec.unmap(param_Frequency) + (sig_FM * param_FM));

			var resonance = resonanceSpec.map(resonanceSpec.unmap(param_Resonance) + (sig_ResonanceModulation * param_ResonanceModulation));
			var sig = MoogLadder.ar(
				sig_In,
				frequency,
				resonance,
			);
			Out.ar(out_Out, sig);
			Out.kr(visual_Frequency, frequency);
		}
	),
	(
		// Status: tested
		name: 'MGain',
		params: [
			'Gain' -> (
				Spec: \db.asSpec.copy.maxval_(12).default_(0),
				// TODO LagTime: 0.1
			),
			'Mute' -> ControlSpec(0, 1, 'lin', 1, 0, ""),
		],
		ugenGraphFunc: {
			|
				in_In,
				out_Out,
				param_Gain,
				param_Mute
			|

			var sig_In = In.ar(in_In);

			var gain = param_Gain.dbamp * Lag.kr(Select.kr(param_Mute, [1, 0], 0.01));

			Out.ar(out_Out, sig_In * gain);
		}
	),
	(
		// Status: tested
		// Inspiration from A-121
		name: 'MMFilter',
		params: [
			'AudioLevel' -> (
				Spec: \amp.asSpec.copy.default_(1), // TODO: updated
				LagTime: 0.1
			),
			'Frequency' -> (
				Spec: \widefreq.asSpec,
				LagTime: 0.1
			),
			'Resonance' -> (
				Spec: \unipolar.asSpec,
				LagTime: 0.1
			),
			'FM' -> (
				Spec: \bipolar.asSpec,
				LagTime: 0.1
			),
			'ResonanceModulation' -> (
				Spec: \bipolar.asSpec,
				LagTime: 0.1
			),
		],
		visuals: [
			'Frequency' -> (
				Spec: \widefreq.asSpec,
			),
		],
		ugenGraphFunc: {
			|
				in_In,
				in_FM,
				in_ResonanceModulation,
				out_Notch,
				out_Highpass,
				out_Bandpass,
				out_Lowpass,
				param_AudioLevel,
				param_Frequency,
				param_Resonance,
				param_FM,
				param_ResonanceModulation,
				visual_Frequency
			|

			var sig_In = In.ar(in_In);
			var sig_FM = In.ar(in_FM);
			var sig_ResonanceModulation = In.ar(in_ResonanceModulation);

			var frequencySpec = \widefreq.asSpec;
			var resonanceSpec = \unipolar.asSpec;

			var sig_In_Atten = sig_In * param_AudioLevel;
			var frequency = frequencySpec.map(frequencySpec.unmap(param_Frequency) + (sig_FM * param_FM));
			var resonance = resonanceSpec.map(resonanceSpec.unmap(param_Resonance) + (sig_ResonanceModulation * param_ResonanceModulation));

			Out.kr(visual_Frequency, frequency);

			Out.ar(
				out_Notch,
				SVF.ar(
					sig_In_Atten,
					frequency,
					resonance,
					lowpass: 0,
					bandpass: 0,
					highpass: 0,
					notch: 1,
					peak: 0
				)
			);
			Out.ar(
				out_Highpass,
				SVF.ar(
					sig_In_Atten,
					frequency,
					resonance,
					lowpass: 0,
					bandpass: 0,
					highpass: 1,
					notch: 0,
					peak: 0
				)
			);
			Out.ar(
				out_Bandpass,
				SVF.ar(
					sig_In_Atten,
					frequency,
					resonance,
					lowpass: 0,
					bandpass: 1,
					highpass: 0,
					notch: 0,
					peak: 0
				)
			);
			Out.ar(
				out_Lowpass,
				SVF.ar(
					sig_In_Atten,
					frequency,
					resonance,
					lowpass: 1,
					bandpass: 0,
					highpass: 0,
					notch: 0,
					peak: 0
				)
			);
		}
	),
	(
		// Status: partly tested, TODO: test in_Reset together with param_Reset
		// Inspiration from A-145
		name: 'MultiLFO',
		ins: [
			'Reset': (
				Description: "Patchable LFO reset trigger",
				Range: [0, 1]
			),
		],
		outs: [
			'InvSaw': (
				Description: "Inverted Saw",
				Range: [-0.25, 0.25]
			),
			'Saw': (
				Description: "Saw",
				Range: [-0.25, 0.25]
			),
			'Sine': (
				Description: "Sine",
				Range: [-0.25, 0.25]
			),
			'Triangle': (
				Description: "Triangle",
				Range: [-0.25, 0.25]
			),
		],
		params: [
			'Frequency' -> (
				Description: "LFO Frequency",
				Spec: ControlSpec(0.01, 50, 'exp', 0, 1, "Hz"),
				LagTime: 0.01
			),
			'Reset' -> (
				Description: "Manual LFO reset trigger",
				Spec: \unipolar.asSpec.copy.step_(1), // TODO: generalize booleans (or triggers)
			)
		],
		ugenGraphFunc: {
			|
				in_Reset,
				out_InvSaw,
				out_Saw,
				out_Sine,
				out_Triangle,
				out_Pulse,
				param_Frequency,
				param_Reset
			|

			var sig_Reset = In.ar(in_Reset);

			// TODO: remove var retrig = (Trig.ar(sig_Reset) + Trig.kr(param_Reset)) > 0; // TODO: remove param?
			var retrig = (Trig.ar(sig_Reset, 1/SampleRate.ir) + Trig.ar(param_Reset, 1/SampleRate.ir)) > 0; // TODO: remove param?

			var invSawPhase = Phasor.ar(retrig, -1/SampleRate.ir*param_Frequency, 0.5, -0.5, 0.5); // TODO: Retrig in middle of saw ramp?
			var invSawSig = invSawPhase * 0.5; // +- 2.5V

			var sawPhase = Phasor.ar(retrig, 1/SampleRate.ir*param_Frequency, -0.5, 0.5, -0.5); // TODO: Retrig in middle of saw ramp?
			var sawSig = sawPhase * 0.5; // +- 2.5V

			var sinePhase = Phasor.ar(retrig, 1/SampleRate.ir*param_Frequency);
			var sineSig = SinOsc.ar(0, sinePhase.linlin(0, 1, 0, 2pi), 0.25); // +- 2.5V

			var trianglePhase = Phasor.ar(retrig, 1/SampleRate.ir*param_Frequency*2, -0.5, 1.5, -0.5);
			var triangleSig = trianglePhase.fold(-0.5, 0.5) * 0.5; // +- 2.5V

			var pulsePhase = Phasor.ar(retrig, 1/SampleRate.ir*param_Frequency*1, 0, 1, 0);
			var pulseSig = ((pulsePhase < 0.5)*0.5)-0.25; // +- 2.5V

			Out.ar(
				out_InvSaw,
				invSawSig
			);

			Out.ar(
				out_Saw,
				sawSig
			);

			Out.ar(
				out_Sine,
				sineSig
			);

			Out.ar(
				out_Triangle,
				triangleSig
			);

			Out.ar(
				out_Pulse,
				pulseSig
			);
		}
	),
	(
		// Status: tested
		// Inspiration from A-110 (but no Sync input)
		name: 'MultiOsc',
		params: [
			'Range' -> (
				Spec: ControlSpec.new(-2, 2, 'lin', 1, 0),
				LagTime: 0.01
			),
			'Tune' -> (
				Spec: ControlSpec.new(-600, 600, 'lin', 0, 0, "cents"),
				LagTime: 0.01
			),
			'PulseWidth' -> (
				Spec: \unipolar.asSpec.copy.default_(0.5),
				LagTime: 0.01
			),
			'FM' -> (
				Spec: \unipolar.asSpec, // TODO: bipolar?
				LagTime: 0.01
			),
			'PWM' -> (
				Spec: \unipolar.asSpec,
				LagTime: 0.01
			),
		],
		ugenGraphFunc: {
			|
			in_FM,
			in_PWM,
			out_Sine,
			out_Triangle,
			out_Saw,
			out_Pulse,
			param_Range,
			param_Tune,
			param_FM,
			param_PulseWidth,
			param_PWM
			|

			var sig_FM = In.ar(in_FM);
			var sig_PWM = In.ar(in_PWM);

			var fullRange = ControlSpec.new(12.midicps, 120.midicps);

			var frequency = fullRange.constrain(
				( // TODO: optimization possibility - implement overridable set handlers and do this calculation in sclang rather than server?
					3 +
					param_Range +
					(param_Tune / 1200) +
					(sig_FM * 10 * param_FM) // 0.1 = 1 oct
				).octcps
			);

			var pulseWidth = (
				param_PulseWidth + (sig_PWM * param_PWM)
				// .clip(0, 1); // TODO: remove ?
			).linlin(0, 1, 0.05, 0.95); // TODO: ??add to other Pulse oscs too

			Out.ar(
				out_Sine,
				SinOsc.ar(frequency) * 0.5
			);

			Out.ar(
				out_Triangle,
				LFTri.ar(frequency) * 0.5 // not band limited
			);

			Out.ar(
				out_Saw,
				Saw.ar(frequency) * 0.5
			);

			Out.ar(
				out_Pulse,
				Pulse.ar(frequency, pulseWidth / 2) * 0.5
			);
		}
	),
	(
		// Status: not tested
		name: 'OGain',
		params: [
			'Gain' -> (
				Spec: \db.asSpec.copy.maxval_(12).default_(0),
				// TODO LagTime: 0.1
			),
			'Mute' -> ControlSpec(0, 1, 'lin', 1, 0, ""),
		],
		ugenGraphFunc: {
			|
				in_In1,
				in_In2,
				in_In3,
				in_In4,
				in_In5,
				in_In6,
				in_In7,
				in_In8,
				out_Out1,
				out_Out2,
				out_Out3,
				out_Out4,
				out_Out5,
				out_Out6,
				out_Out7,
				out_Out8,
				param_Gain,
				param_Mute
			|

			var sig_In1 = In.ar(in_In1);
			var sig_In2 = In.ar(in_In2);
			var sig_In3 = In.ar(in_In3);
			var sig_In4 = In.ar(in_In4);
			var sig_In5 = In.ar(in_In5);
			var sig_In6 = In.ar(in_In6);
			var sig_In7 = In.ar(in_In7);
			var sig_In8 = In.ar(in_In8);

			var gain = param_Gain.dbamp * Lag.kr(Select.kr(param_Mute, [1, 0], 0.01));

			Out.ar(out_Out1, sig_In1 * gain);
			Out.ar(out_Out2, sig_In2 * gain);
			Out.ar(out_Out3, sig_In3 * gain);
			Out.ar(out_Out4, sig_In4 * gain);
			Out.ar(out_Out5, sig_In5 * gain);
			Out.ar(out_Out6, sig_In6 * gain);
			Out.ar(out_Out7, sig_In7 * gain);
			Out.ar(out_Out8, sig_In8 * gain);
		}
	),
	(
		// Status: tested
		// TODO: or just extend LinMixer, make it bipolar?
		name: 'PolMixer',
		params: [
			'In1' -> (
				Spec: \bipolar.asSpec,
				LagTime: 0.1
			),
			'In2' -> (
				Spec: \bipolar.asSpec,
				LagTime: 0.1
			),
			'In3' -> (
				Spec: \bipolar.asSpec,
				LagTime: 0.1
			),
			'In4' -> (
				Spec: \bipolar.asSpec,
				LagTime: 0.1
			),
			'Out' -> ( // TODO: 0 is default, is that right?
				Spec: \unipolar.asSpec,
				LagTime: 0.1
			)
		],
		ugenGraphFunc: {
			|
				in_In1,
				in_In2,
				in_In3,
				in_In4,
				out_Out,
				param_In1,
				param_In2,
				param_In3,
				param_In4,
				param_Out
			|

			var sig_In1 = In.ar(in_In1);
			var sig_In2 = In.ar(in_In2);
			var sig_In3 = In.ar(in_In3);
			var sig_In4 = In.ar(in_In4);

			Out.ar(
				out_Out,
				(
					(sig_In1 * param_In1) +
					(sig_In2 * param_In2) +
					(sig_In3 * param_In3) +
					(sig_In4 * param_In4)
				) * param_Out
			);
		}
	),
	(
		// Status: partly tested. TODO: review modulation input mapping
		name: 'PShift',
		params: [
			'PitchRatio' -> (
				Spec: ControlSpec(0, 4, default: 1),
				LagTime: 0.1
			),
			'PitchDispersion' -> (
				Spec: ControlSpec(0, 4),
				LagTime: 0.1
			),
			'TimeDispersion' -> (
				Spec: ControlSpec(0, 1),
				LagTime: 0.1
			),
			'PitchRatioModulation' -> \bipolar.asSpec,
			'PitchDispersionModulation' -> \bipolar.asSpec,
			'TimeDispersionModulation' -> \bipolar.asSpec
		],
		ugenGraphFunc: {
			|
				in_Left,
				in_Right,
				in_PitchRatioModulation,
				in_PitchDispersionModulation,
				in_TimeDispersionModulation,
				out_Left,
				out_Right,
				param_PitchRatio,
				param_PitchDispersion,
				param_TimeDispersion,
				param_PitchRatioModulation,
				param_PitchDispersionModulation,
				param_TimeDispersionModulation
			|

			var pitchRatioSpec = ControlSpec(0, 4, default: 1);
			var pitchDispersionSpec = ControlSpec(0, 4);
			var timeDispersionSpec = ControlSpec(0, 1);

			var sig_Left = In.ar(in_Left);
			var sig_Right = In.ar(in_Right);
			var sig_PitchRatioModulation = In.ar(in_PitchRatioModulation);
			var sig_PitchDispersionModulation = In.ar(in_PitchDispersionModulation);
			var sig_TimeDispersionModulation = In.ar(in_TimeDispersionModulation);

			var shifted = PitchShift.ar(
				[sig_Left, sig_Right],
				0.2,
				pitchRatioSpec.map(
					pitchRatioSpec.unmap(param_PitchRatio) +
					(sig_PitchRatioModulation * param_PitchRatioModulation)
				),
				pitchDispersionSpec.map(
					pitchDispersionSpec.unmap(param_PitchDispersion) +
					(sig_PitchDispersionModulation * param_PitchDispersionModulation)
				),
				timeDispersionSpec.map(
					timeDispersionSpec.unmap(param_TimeDispersion) +
					(sig_TimeDispersionModulation * param_TimeDispersionModulation)
				) / 5 // time dispersion cannot exceed windowSize (0.2)
			);

			Out.ar(out_Left, shifted[0]);
			Out.ar(out_Right, shifted[1]);
		}
	),
	(
		// Status: tested
		name: 'PulseOsc',
		params: [
			'Range' -> (
				Spec: ControlSpec.new(-2, 2, 'lin', 1, 0),
				LagTime: 0.01
			),
			'Tune' -> (
				Spec: ControlSpec.new(-600, 600, 'lin', 0, 0, "cents"),
				LagTime: 0.01
			),
			'PulseWidth' -> (
				Spec: \unipolar.asSpec.copy.default_(0.5),
				LagTime: 0.01
			),
			'FM' -> (
				Spec: \unipolar.asSpec, // TODO: bipolar?
				LagTime: 0.01
			),
			'PWM' -> (
				Spec: \unipolar.asSpec.copy.default_(0.4),
				LagTime: 0.01
			),
		],
		ugenGraphFunc: {
			|
				in_FM,
				in_PWM,
				out_Out,
				param_Range,
				param_Tune,
				param_FM,
				param_PulseWidth,
				param_PWM
			|

			var sig_FM = In.ar(in_FM);
			var sig_PWM = In.ar(in_PWM);

			var fullRange = ControlSpec(12.midicps, 120.midicps);

			var frequency = fullRange.constrain(
				(
					3 +
					param_Range +
					(param_Tune / 1200) +
					(sig_FM * 10 * param_FM) // 0.1 = 1 oct
				).octcps
			);

			var pulseWidth = (
				param_PulseWidth + (sig_PWM * param_PWM)
			).clip(0, 1);

			Out.ar(
				out_Out,
				Pulse.ar(frequency, pulseWidth / 2) * 0.5
			);
		}
	),
	(
		// Status: not tested
		name: 'QGain',
		params: [
			'Gain' -> (
				Spec: \db.asSpec.copy.maxval_(12).default_(0),
				// TODO LagTime: 0.1
			),
			'Mute' -> ControlSpec(0, 1, 'lin', 1, 0, ""),
		],
		ugenGraphFunc: {
			|
				in_In1,
				in_In2,
				in_In3,
				in_In4,
				out_Out1,
				out_Out2,
				out_Out3,
				out_Out4,
				param_Gain,
				param_Mute
			|

			var sig_In1 = In.ar(in_In1);
			var sig_In2 = In.ar(in_In2);
			var sig_In3 = In.ar(in_In3);
			var sig_In4 = In.ar(in_In4);

			var gain = param_Gain.dbamp * Lag.kr(Select.kr(param_Mute, [1, 0], 0.01));

			Out.ar(out_Out1, sig_In1 * gain);
			Out.ar(out_Out2, sig_In2 * gain);
			Out.ar(out_Out3, sig_In3 * gain);
			Out.ar(out_Out4, sig_In4 * gain);
		}
	),
	(
		// Status: partly tested
		name: 'SampHold',
		ugenGraphFunc: {
			|
				in_In,
				in_Trig,
				out_Out
			|

			var sig_In = In.ar(in_In);
			var sig_Trig = In.ar(in_Trig);

			Out.ar(
				out_Out,
				Latch.ar(sig_In, sig_Trig)
			);
		}
	),
	(
		// From https://en.wikibooks.org/wiki/Designing_Sound_in_SuperCollider/Schroeder_reverb
		name: 'Rev1',
		params: [
			'Volume' -> (
				Spec: \db.asSpec.copy.maxval_(12).default_(-10),
				LagTime: 0.1
			),
			'PreDelay' -> (
				Spec: ControlSpec(1, 1000, default: 64, units: "ms"),
				LagTime: 0.5
			),
			'DelTime_1' -> (
				Spec: ControlSpec(64, 1000, default: 101, units: "ms"), // minimum = s.options.blockize
				LagTime: 0.5
			),
			'DelTime_2' -> (
				Spec: ControlSpec(64, 1000, default: 143, units: "ms"), // minimum = s.options.blockize
				LagTime: 0.5
			),
			'DelTime_3' -> (
				Spec: ControlSpec(64, 1000, default: 165, units: "ms"), // minimum = s.options.blockize
				LagTime: 0.5
			),
			'DelTime_4' -> (
				Spec: ControlSpec(64, 1000, default: 177, units: "ms"), // minimum = s.options.blockize
				LagTime: 0.5
			),
			'DelAtten_1' -> (
				Spec: \unipolar.asSpec.copy.maxval_(0.5).default_(0.4),
				LagTime: 0.1
			),
			'DelAtten_2' -> (
				Spec: \unipolar.asSpec.copy.maxval_(0.5).default_(0.37),
				LagTime: 0.1
			),
			'DelAtten_3' -> (
				Spec: \unipolar.asSpec.copy.maxval_(0.5).default_(0.333),
				LagTime: 0.1
			),
			'DelAtten_4' -> (
				Spec: \unipolar.asSpec.copy.maxval_(0.5).default_(0.3),
				LagTime: 0.1
			)
		],
		ugenGraphFunc: { |
				param_Volume,
				param_PreDelay,
				param_DelTime_1,
				param_DelTime_2,
				param_DelTime_3,
				param_DelTime_4,
				param_DelAtten_1,
				param_DelAtten_2,
				param_DelAtten_3,
				param_DelAtten_4,
				in_Left,
				in_Right,
				out_Left,
				out_Right
			|
			var sig_Left = In.ar(in_Left, 1);
			var sig_Right = In.ar(in_Right, 1);
			var amp = param_Volume.dbamp;

			// Here we give delay times in milliseconds, convert to seconds,
			// then compensate with ControlDur for the one-block delay
			// which is always introduced when using the LocalIn/Out fdbk loop
			var deltimes = [param_DelTime_1, param_DelTime_2, param_DelTime_3, param_DelTime_4] * 0.001 - ControlDur.ir;

			// Read our 4-channel delayed signals back from the feedback loop
			var delrd = LocalIn.ar(4);

			// This will be our eventual output, which will also be recirculated
			var output = [sig_Left, sig_Right] + delrd[[0,1]];

			// Cross-fertilise the four delay lines with each other:
			var sig = [output[0]+output[1], output[0]-output[1], delrd[2]+delrd[3], delrd[2]-delrd[3]];
			sig = [sig[0]+sig[2], sig[1]+sig[3], sig[0]-sig[2], sig[1]-sig[3]];
			// Attenutate the delayed signals so they decay:
			sig = sig * [param_DelAtten_1, param_DelAtten_2, param_DelAtten_3, param_DelAtten_4];

			// Apply the delays and send the signals into the feedback loop
			LocalOut.ar(DelayC.ar(sig, deltimes, deltimes));

			output = DelayC.ar(output, 1, param_PreDelay/1000);

			Out.ar(out_Left, output[0] * amp);
			Out.ar(out_Right, output[1] * amp);
		}
	),
	(
		// Status: partly tested
		name: 'RingMod',
		ugenGraphFunc: {
			|
				in_In,
				in_Carrier, // TODO: naming?
				out_Out
			|

			Out.ar(
				out_Out,
				In.ar(in_In) * In.ar(in_Carrier)
			);
		}
	),
	(
		// Status: tested, TODO: make a script
		name: 'Noise',
		ugenGraphFunc: {
			|
				out_Out
			|

			Out.ar(
				out_Out,
				WhiteNoise.ar
			);
		}
	),
	(
		// Status: tested
		name: 'SawOsc',
		params: [
			'Range' -> (
				Spec: ControlSpec.new(-2, 2, 'lin', 1, 0),
				LagTime: 0.01
			),
			'Tune' -> (
				Spec: ControlSpec.new(-600, 600, 'lin', 0, 0, "cents"),
				LagTime: 0.01
			),
			'FM' -> (
				Spec: \unipolar.asSpec, // TODO: bipolar?
				LagTime: 0.01
			),
		],
		ugenGraphFunc: {
			|
				in_FM,
				out_Out,
				param_Range,
				param_Tune,
				param_FM
			|

			var sig_FM = In.ar(in_FM);

			var fullRange = ControlSpec(12.midicps, 120.midicps);

			var frequency = fullRange.constrain(
				( // TODO: optimization possibility - implement overridable set handlers and do this calculation in sclang rather than server?
					3 +
					param_Range +
					(param_Tune / 1200) +
					(sig_FM * 10 * param_FM) // 0.1 = 1 oct
				).octcps
			);

			Out.ar(
				out_Out,
				Saw.ar(frequency) * 0.5
			);
		}
	),
	(
		// TODO: align out and param naming wrt Xyz_1 vs Xyz1
		// Status: not tested
		// Inspiration from A-155
		name: 'Seq1',
		ins: (
			'Clock': (
				Description: ""
			),
			'Reset': (
				Description: ""
			),
			'SampleAndHoldCtrl1': (
				Description: ""
			),
			'GlideCtrl1': (
				Description: ""
			),
			'SampleAndHoldCtrl2': (
				Description: ""
			),
			'GlideCtrl2': (
				Description: ""
			)
		),
		outs: (
			'Trig1': (
				Description: ""
			),
			'Trig2': (
				Description: ""
			),
			'Gate': (
				Description: ""
			),
			'PreOut1': (
				Description: ""
			),
			'Out1': (
				Description: ""
			),
			'PreOut2': (
				Description: ""
			),
			'Out2': (
				Description: ""
			)
		),
		params: {
			var numSteps = 8;
			var numRows = 2;
			var result = [
					'Reset' -> (
						Spec: \unipolar.asSpec.copy.step_(1), // TODO
						Description: ""
					),
					'Step' -> \unipolar.asSpec.copy.step_(1), // TODO
					'Range' -> ControlSpec.new(0, 2, step: 1, default: 0), // 0 = 1V, 1 = 2V, 2 = 4V
					'Scale' -> \unipolar.asSpec.copy.default_(1), // TODO
					'Glide_1' -> \unipolar.asSpec, // TODO: longer, up to 10 seconds lag as in Softube slew
					'Glide_2' -> \unipolar.asSpec // TODO: longer, up to 10 seconds lag as in Softube slew
				] ++
				(
					numRows.collect { |rowIndex|
						numSteps.collect { |stepIndex|
							"Trig_"++(rowIndex+1)++"_"++(stepIndex+1) -> ControlSpec(0, 1, 'lin', 1, 0, "")
						} ++
						numSteps.collect { |stepIndex|
							"Value_"++(rowIndex+1)++"_"++(stepIndex+1) -> \bipolar.asSpec // TODO: probably make this unipolar to comply with original module
						}
					}.flatten ++
					numSteps.collect { |stepIndex|
						"Gate_"++(stepIndex+1) -> ControlSpec(0, 1, 'lin', 1, 0, "") // TODO: DRY the gate/reset/boolean specs
					}
				).collect { |assoc| assoc.key.asSymbol -> assoc.value };
			result; // TODO: remember bug, perform validation that ensures array includes _symbol_ -> definition associations
		},
		visuals: [
			'Position' -> (
				Spec: \unipolar.asSpec,
			),
		],
		ugenGraphFunc: {
			|
				in_Clock,
				in_Reset,
				in_SampleAndHoldCtrl1,
				in_GlideCtrl1,
				in_SampleAndHoldCtrl2,
				in_GlideCtrl2,
				out_Trig1,
				out_Trig2,
				out_Gate,
				out_PreOut1,
				out_Out1,
				out_PreOut2,
				out_Out2,
				param_Reset,
				param_Step,
				param_Range,
				param_Scale,
				param_Glide_1,
				param_Glide_2,
				param_Trig_1_1,
				param_Trig_1_2,
				param_Trig_1_3,
				param_Trig_1_4,
				param_Trig_1_5,
				param_Trig_1_6,
				param_Trig_1_7,
				param_Trig_1_8,
				param_Trig_2_1,
				param_Trig_2_2,
				param_Trig_2_3,
				param_Trig_2_4,
				param_Trig_2_5,
				param_Trig_2_6,
				param_Trig_2_7,
				param_Trig_2_8,
				param_Value_1_1,
				param_Value_1_2,
				param_Value_1_3,
				param_Value_1_4,
				param_Value_1_5,
				param_Value_1_6,
				param_Value_1_7,
				param_Value_1_8,
				param_Value_2_1,
				param_Value_2_2,
				param_Value_2_3,
				param_Value_2_4,
				param_Value_2_5,
				param_Value_2_6,
				param_Value_2_7,
				param_Value_2_8,
				param_Gate_1,
				param_Gate_2,
				param_Gate_3,
				param_Gate_4,
				param_Gate_5,
				param_Gate_6,
				param_Gate_7,
				param_Gate_8,
				visual_Position
			|

			var sig_Clock = In.ar(in_Clock);
			var sig_Reset = In.ar(in_Reset);
			var sig_SampleAndHoldCtrl1 = In.ar(in_SampleAndHoldCtrl1);
			var sig_GlideCtrl1 = In.ar(in_GlideCtrl1);
			var sig_SampleAndHoldCtrl2 = In.ar(in_SampleAndHoldCtrl2);
			var sig_GlideCtrl2 = In.ar(in_GlideCtrl2);

			var reset = (Trig1.ar(sig_Reset, 1/SampleRate.ir) + Trig.ar(param_Reset, 1/SampleRate.ir)) > 0; // TODO: remove param?

			var clock = (Trig1.ar(sig_Clock, 1/SampleRate.ir) + Trig.ar(param_Step, 1/SampleRate.ir)) > 0; // TODO: remove param?

			var trigSeq1 = Dseq(
				[
					param_Trig_1_1, param_Trig_1_2, param_Trig_1_3, param_Trig_1_4, param_Trig_1_5, param_Trig_1_6, param_Trig_1_7, param_Trig_1_8
				],
				inf
			);

			var trigSeq2 = Dseq(
				[
					param_Trig_2_1, param_Trig_2_2, param_Trig_2_3, param_Trig_2_4, param_Trig_2_5, param_Trig_2_6, param_Trig_2_7, param_Trig_2_8
				],
				inf
			);

			var gateSeq = Dseq(
				[
					param_Gate_1, param_Gate_2, param_Gate_3, param_Gate_4, param_Gate_5, param_Gate_6, param_Gate_7, param_Gate_8
				],
				inf
			);

			var valueSeq1 = Dseq(
				[
					param_Value_1_1, param_Value_1_2, param_Value_1_3, param_Value_1_4, param_Value_1_5, param_Value_1_6, param_Value_1_7, param_Value_1_8
				],
				inf
			);

			var valueSeq2 = Dseq(
				[
					param_Value_2_1, param_Value_2_2, param_Value_2_3, param_Value_2_4, param_Value_2_5, param_Value_2_6, param_Value_2_7, param_Value_2_8
				],
				inf
			);

			var trig1 = Demand.ar(clock, reset, trigSeq1) * clock; // TODO: clock usage here means trig length is determined by outside clock signal. right or wrong?
			// var trig1 = Trig.ar(Demand.ar(clock, reset, trigSeq1) * clock, 1/SampleRate.ir);

			var trig2 = Demand.ar(clock, reset, trigSeq2) * clock; // TODO: clock usage here means trig length is determined by outside clock signal. right or wrong?
			// var trig2 = Trig.ar(Demand.ar(clock, reset, trigSeq2) * clock, 1/SampleRate.ir);

			var gate = Latch.ar(Demand.ar(clock, reset, gateSeq), clock);
			var freq1 = Demand.ar(clock, reset, valueSeq1) * SelectX.kr(param_Range, [0.1, 0.2, 0.4]);
			var freq2 = Demand.ar(clock, reset, valueSeq2) * param_Scale; // TODO: Scale 0 .. 6.5V ?

			// var latchedFreq1 = Latch.ar(freq1, trig1);
			var latchedFreq1 = Latch.ar(freq1, sig_SampleAndHoldCtrl1); // TODO: consider semi-modular

			// var latchedFreq2 = Latch.ar(freq2, trig2);
			var latchedFreq2 = Latch.ar(freq2, sig_SampleAndHoldCtrl2); // TODO: consider semi-modular

			// TODO: remove phase
			var phaseSeq = Dseq([ 0, 1, 2, 3, 4, 5, 6, 7 ], inf);
			var phase = Demand.ar(clock, reset, phaseSeq);

			Out.kr(visual_Position, phase);

			Out.ar(
				out_Trig1,
				Trig1.ar(trig1, 1/60) * 0.5 // TODO: ~5V, TODO: 1/60 second trig length
			);
			Out.ar(
				out_Trig2,
				Trig1.ar(trig2, 1/60) * 0.5 // TODO: ~5V, TODO: 1/60 second trig length
			);
			Out.ar(
				out_Gate,
				gate
			);
			Out.ar(
				out_PreOut1,
				freq1
			);
			Out.ar(
				out_Out1,
				SelectX.ar(sig_GlideCtrl1, [Lag.ar(latchedFreq1, param_Glide_1), latchedFreq1])
			);
			Out.ar(
				out_PreOut2,
				freq2
			);
			Out.ar(
				out_Out2,
				SelectX.ar(sig_GlideCtrl2, [Lag.ar(latchedFreq2, param_Glide_2), latchedFreq2])
			);
		}
	),
	(
		// Status: tested
		name: 'SGain',
		params: [
			'Gain' -> (
				Spec: \db.asSpec.copy.maxval_(12).default_(0),
				// TODO LagTime: 0.1
			),
			'Mute' -> ControlSpec(0, 1, 'lin', 1, 0, ""),
		],
		ugenGraphFunc: {
			|
				in_Left,
				in_Right,
				out_Left,
				out_Right,
				param_Gain,
				param_Mute
			|

			var sig_Left = In.ar(in_Left);
			var sig_Right = In.ar(in_Right);

			var gain = param_Gain.dbamp * Lag.kr(Select.kr(param_Mute, [1, 0], 0.01));

			Out.ar(out_Left, sig_Left * gain);
			Out.ar(out_Right, sig_Right * gain);
		}
	),
	(
		// Status: partly tested, TODO: test in_Reset together with param_Reset
		// Inspiration from A-145
		name: 'SineLFO',
		params: [
			'Frequency' -> (
				Spec: ControlSpec(0.01, 50, 'exp', 0, 1, "Hz"),
				LagTime: 0.01
			),
			'Reset' -> \unipolar.asSpec.copy.step_(1), // TODO
		],
		ugenGraphFunc: {
			|
				in_Reset,
				out_Out,
				param_Frequency,
				param_Reset
			|

			var sig_Reset = In.ar(in_Reset);

			// TODO: remove var retrig = (Trig.ar(sig_Reset) + Trig.kr(param_Reset)) > 0; // TODO: remove param?
			var retrig = (Trig.ar(sig_Reset, 1/SampleRate.ir) + Trig.ar(param_Reset, 1/SampleRate.ir)) > 0; // TODO: remove param?

			var sinePhase = Phasor.ar(retrig, 1/SampleRate.ir*param_Frequency);
			var sineSig = SinOsc.ar(0, sinePhase.linlin(0, 1, 0, 2pi), 0.25); // +- 2.5V

			Out.ar(
				out_Out,
				sineSig
			);
		}
	),
	(
		// Status: tested
		name: 'SineOsc',
		params: [
			'Range' -> (
				Spec: ControlSpec.new(-2, 2, 'lin', 1, 0),
				LagTime: 0.01
			),
			'Tune' -> (
				Spec: ControlSpec.new(-600, 600, 'lin', 0, 0, "cents"),
				LagTime: 0.01
			),
			'FM' -> (
				Spec: \unipolar.asSpec, // TODO: bipolar?
				LagTime: 0.01
			),
		],
		ugenGraphFunc: {
			|
				in_FM,
				out_Out,
				param_Range,
				param_Tune,
				param_FM
			|

			var sig_FM = In.ar(in_FM);

			var fullRange = ControlSpec(12.midicps, 120.midicps);

			var frequency = fullRange.constrain(
				( // TODO: optimization possibility - implement overridable set handlers and do this calculation in sclang rather than server?
					3 +
					param_Range +
					(param_Tune / 1200) +
					(sig_FM * 10 * param_FM) // 0.1 = 1 oct
				).octcps
			);

			Out.ar(
				out_Out,
				SinOsc.ar(frequency) * 0.5
			);
		}
	),
	(
		// Status: untested
		name: 'SPVoice',
		params: [
			'Gate' -> ControlSpec(0, 1, step: 1, default: 0), // TODO: DRY the gate/reset/boolean specs
			'SampleStart' -> \unipolar.asSpec,
			'SampleEnd' -> \unipolar.asSpec.copy.default_(1),
			'LoopPoint' -> \unipolar.asSpec,
			'LoopEnable' -> ControlSpec(0, 1, step: 1, default: 0),
			'Frequency' -> \freq.asSpec,
			'RootFrequency' -> \freq.asSpec, // default root is 440 = A4
			'Volume' -> \db.asSpec.copy.default_(-10),
			'Pan' -> \pan.asSpec,
			'FM' -> (
				Spec: \unipolar.asSpec, // TODO: bipolar? nah: enfore unipolar on other modules
				LagTime: 0.01
			),
		],
		sampleSlots: [
			'Sample' -> (
				Channels: [1, 2]
			) // TODO: include metadata on whether samples are supposed to be enabled for read, write or both, and whether to set a default size for initial sample(s) (to set up a fixed recording buffer, etc)
		],
		visuals: [
			'Phase' -> (
				Spec: \unipolar.asSpec,
			),
			'Gate' -> (
				Spec: ControlSpec(0, 1, step: 1) // TODO: DRY the gate/reset/boolean specs
			),
			'Playing' -> (
				Spec: ControlSpec(0, 1, step: 1) // TODO: DRY the gate/reset/boolean specs
			),
		],
		ugenGraphFunc: {
			|
				in_Gate,
				in_FM,
				out_Left,
				out_Right,
				// param_Bufnum, // TODO
				param_Gate,
				param_SampleStart, // start point of playing back sample normalized to 0..1
				param_SampleEnd, // end point of playing back sample normalized to 0..1. sampleEnd prior to sampleStart will play sample reversed
				param_LoopPoint, // loop point position between sampleStart and sampleEnd expressed in 0..1
				param_LoopEnable, // loop enabled switch (1 = play looped, 0 = play oneshot). argument is fixed once gated
				param_Frequency,
				param_RootFrequency,
				param_Volume,
				param_Pan,
				param_FM,
				visual_Phase,
				visual_Gate,
				visual_Playing,
				numchannels_Sample,
				bufnums_Sample=#[0, 0]
			|

			var sig_Gate = In.ar(in_Gate);
			var sig_FM = In.ar(in_FM);

			var fullRange = ControlSpec(12.midicps, 120.midicps); // TODO: nicked from Osc implementations

			var frequency = fullRange.constrain( // TODO: variant of version in Osc implementations
				( // TODO: optimization - implement overridable set handlers and do this calculation in sclang rather than server
					param_Frequency.cpsoct +
					(sig_FM * 10 * param_FM) // 0.1 = 1 oct
				).octcps
			);
			// var gate = param_Gate;
			var gate = ((sig_Gate > 0) + (K2A.ar(param_Gate) > 0)) > 0;

			var latched_sampleStart = Latch.ar(K2A.ar(param_SampleStart), gate); // parameter only has effect at time synth goes from gate 0 to 1
			var latched_sampleEnd = Latch.ar(K2A.ar(param_SampleEnd), gate); // parameter only has effect at time synth goes from gate 0 to 1
			var latched_loopPoint = Latch.ar(K2A.ar(param_LoopPoint), gate); // parameter only has effect at time synth goes from gate 0 to 1
			var latched_loopEnable = Latch.ar(K2A.ar(param_LoopEnable), gate); // parameter only has effect at time synth goes from gate 0 to 1

			// TODO: remove, bufnums are to be constant var latched_bufnum = Latch.ar(K2A.ar(param_Bufnum), gate); // parameter only has effect at time synth goes from gate 0 to 1

			var rate = frequency/param_RootFrequency;
			var direction = (latched_sampleEnd-latched_sampleStart).sign; // 1 = forward, -1 = backward
			var leftmostSamplePosExtent = min(latched_sampleStart, latched_sampleEnd);
			var rightmostSamplePosExtent = max(latched_sampleStart, latched_sampleEnd);

			var mono_bufnum = bufnums_Sample[0];
			var stereo_bufnum = bufnums_Sample[1];

/*
			var monoSampleIsLoaded = Latch.ar(
				(numchannels_Sample > 0) * (numchannels_Sample < 2),
				gate
			);
			var stereoSampleIsLoaded = Latch.ar(
				(numchannels_Sample > 1) * (numchannels_Sample < 3),
				gate
			);

			var bufnum = Latch.ar(
				(monoSampleIsLoaded * mono_bufnum)
				+ 
				(stereoSampleIsLoaded * stereo_bufnum),
				gate
			); // "fixes" bufnum to correct channelcount
*/
			var monoSampleIsLoaded = (numchannels_Sample > 0) * (numchannels_Sample < 2);
			var stereoSampleIsLoaded = (numchannels_Sample > 1) * (numchannels_Sample < 3);
			var bufnum = (monoSampleIsLoaded * mono_bufnum) + (stereoSampleIsLoaded * stereo_bufnum);

			// var onset = Latch.ar(sampleStart, Impulse.ar(0)); // "fixes" onset to sample start at the time of spawning the synth, whereas sample end and *absolute* loop position (calculated from possibly modulating start and end positions) may vary
			var onset = Latch.ar(latched_sampleStart, gate); // "fixes" onset to sample start at the time of spawning the synth, whereas sample end and *absolute* loop position (calculated from possibly modulating start and end positions) may vary

			//var bufDur = BufDur.kr(bufnums_Sample);
			var bufDur = BufDur.kr(bufnum);
			var bufDurDiv = Select.kr(bufDur > 0, [1, bufDur]); // weird way to avoid divide by zero in second sweep argument in the rare case of a buffer having 0 samples which stalls scsynth. there's gotta be a better way to work around this (by not dividing by bufDur) ... TODO
			var sweep = Sweep.ar(gate, rate/bufDurDiv*direction); // sample duration normalized to 0..1 (sweeping 0..1 sweeps entire sample).
			var oneshotPhase = onset + sweep; // align phase to actual onset (fixed sample start at the time of spawning the synth)

			var fwdOneshotPhaseDone = ((oneshotPhase > latched_sampleEnd) * (direction > (-1))) > 0; // condition fulfilled if phase is above current sample end and direction is positive
			var revOneshotPhaseDone = ((oneshotPhase < latched_sampleEnd) * (direction < 0)) > 0; // condition fulfilled if phase is above current sample end and direction is positive
			var loopPhaseStartTrig = (fwdOneshotPhaseDone + revOneshotPhaseDone) > 0;

			var oneshotSize = rightmostSamplePosExtent-leftmostSamplePosExtent;
			var loopOffset = latched_loopPoint*oneshotSize; // loop point normalized to entire sample 0..1
			var loopSize = (1-latched_loopPoint)*oneshotSize; // TODO: this should be fixed / latch for every initialized loop phase / run
			var absoluteLoopPoint = latched_sampleStart + (loopOffset * direction); // TODO: this should be fixed / latch for every initialized loop phase / run

			var loopPhaseOnset = Latch.ar(oneshotPhase, loopPhaseStartTrig);
			var loopPhase = (oneshotPhase-loopPhaseOnset).wrap(0, loopSize * direction) + absoluteLoopPoint; // TODO
			// var loopPhase = oneshotPhase.wrap(sampleStart, sampleEnd);

			/*
			TODO: debugging
			loopPhaseStartTrig.poll(label: 'loopPhaseStartTrig');
			absoluteLoopPoint.poll(label: 'absoluteLoopPoint');
			loopPhaseOnset.poll(label: 'loopPhaseOnset');
			oneshotPhase.poll(label: 'oneshotPhase');
			loopPhase.poll(label: 'loopPhase');
			loopSize.poll(label: 'loopSize');
			*/

			var phase = Select.ar(loopPhaseStartTrig, [oneshotPhase, loopPhase]);

			var isForwardDirectionAndOkPlaying = ((fwdOneshotPhaseDone < 1) + (latched_loopEnable > 0)) > 0; // basically: as long as direction is forward and phaseFromStart < sampleEnd or latched_loopEnable == 1, continue playing (audition sound)
			var isReversedDirectionAndOkPlaying = ((revOneshotPhaseDone < 1) + (latched_loopEnable > 0)) > 0; // basically: as long as direction is backward and phaseFromStart > sampleEnd or latched_loopEnable == 1, continue playing (audition sound)

			var stillPlaying = isForwardDirectionAndOkPlaying * isReversedDirectionAndOkPlaying * gate;

			var sig = (
				(
					BufRd.ar( // TODO: tryout BLBufRd
						1,
						mono_bufnum,
						phase.linlin(0, 1, 0, BufFrames.kr(mono_bufnum)),
						interpolation: 4
					) ! 2 * monoSampleIsLoaded
				) + 
				(
					BufRd.ar( // TODO: tryout BLBufRd
						2,
						stereo_bufnum,
						phase.linlin(0, 1, 0, BufFrames.kr(stereo_bufnum)),
						interpolation: 4
					) * stereoSampleIsLoaded
				)
			);

			//SendTrig.kr(Impulse.kr(60),0,phase);
			/*
			var sig = BLBufRd.ar(
			bufnum,
			phase.linlin(0, 1, 0, BufFrames.kr(bufnum)),
			2
			) ! 2; // TODO: tryout BLBufRd
			*/

/*
			sig = sig * (((fwdOneshotPhaseDone < 1) + (latched_loopEnable > 0)) > 0); // basically: as long as direction is forward and phaseFromStart < sampleEnd or latched_loopEnable == 1, continue playing (audition sound)
			sig = sig * (((revOneshotPhaseDone < 1) + (latched_loopEnable > 0)) > 0); // basically: as long as direction is backward and phaseFromStart > sampleEnd or latched_loopEnable == 1, continue playing (audition sound)
*/
/*
			sig = sig * (((fwdOneshotPhaseDone < 1) + (latched_loopEnable > 0)) > 0) * gate; // basically: as long as direction is forward and phaseFromStart < sampleEnd or latched_loopEnable == 1, continue playing (audition sound)
			sig = sig * (((revOneshotPhaseDone < 1) + (latched_loopEnable > 0)) > 0) * gate; // basically: as long as direction is backward and phaseFromStart > sampleEnd or latched_loopEnable == 1, continue playing (audition sound)
*/
			sig = sig * stillPlaying;

			sig = Balance2.ar(sig[0], sig[1], param_Pan);

			sig = sig * param_Volume.dbamp;
			Out.ar(out_Left, sig[0]);
			Out.ar(out_Right, sig[1]);
			Out.kr(visual_Phase, Gate.ar(phase, stillPlaying));
			Out.kr(visual_Gate, gate);
			Out.kr(visual_Playing, stillPlaying);
		}
	),
	(
		// Status: tested
		name: 'TestGen',
		params: [
			'Frequency' -> (
				Spec: \widefreq.asSpec,
				LagTime: 0 // TODO: all lag times have to be 0 if params with \db spec (such as param_Amplitude) are used (fixed by resorting to NamedControls in R?)
			),
			'Amplitude' -> \db.asSpec,
			'Wave' -> ControlSpec(0, 1, step: 1, default: 0)
		],
		ugenGraphFunc: {
			|
				out_Out,
				param_Frequency,
				param_Amplitude,
				param_Wave
			|

			Out.ar(out_Out, SelectX.ar(param_Wave, [SinOsc.ar(param_Frequency), WhiteNoise.ar]) * param_Amplitude.dbamp);
		}
	),
	(
		// Status: tested
		name: 'TriOsc',
		params: [
			'Range' -> (
				Spec: ControlSpec.new(-2, 2, 'lin', 1, 0),
				LagTime: 0.01
			),
			'Tune' -> (
				Spec: ControlSpec.new(-600, 600, 'lin', 0, 0, "cents"),
				LagTime: 0.01
			),
			'FM' -> (
				Spec: \unipolar.asSpec, // TODO: bipolar?
				LagTime: 0.01
			),
		],
		ugenGraphFunc: {
			|
				in_FM,
				out_Out,
				param_Range,
				param_Tune,
				param_FM
			|

			var sig_FM = In.ar(in_FM);

			var fullRange = ControlSpec(12.midicps, 120.midicps);

			var frequency = fullRange.constrain(
				( // TODO: optimization possibility - implement overridable set handlers and do this calculation in sclang rather than server?
					3 +
					param_Range +
					(param_Tune / 1200) +
					(sig_FM * 10 * param_FM) // 0.1 = 1 oct
				).octcps
			);

			Out.ar(
				out_Out,
				LFTri.ar(frequency) * 0.5 // TODO: not band-limited
			);
		}
	),
	(
		// Status: not tested
		name: 'XFader',
		params: [
			'Fade' -> \bipolar.asSpec, // TODO: remove need for .asSpec
			'TrimA' -> \db.asSpec.copy.maxval_(12),
			'TrimB' -> \db.asSpec.copy.maxval_(12),
			'Master' -> \db.asSpec.copy.maxval_(12)
		],
		ugenGraphFunc: {
			|
				in_InALeft,
				in_InARight,
				in_InBLeft,
				in_InBRight,
				out_Left,
				out_Right,
				param_Fade,
				param_TrimA,
				param_TrimB,
				param_Master
			|

			var sig_InALeft = In.ar(in_InALeft);
			var sig_InARight = In.ar(in_InARight);
			var sig_InBLeft = In.ar(in_InBLeft);
			var sig_InBRight = In.ar(in_InBRight);

			var sig_inA = [sig_InALeft, sig_InARight] * param_TrimA.dbamp;
			var sig_inB = [sig_InBLeft, sig_InBRight] * param_TrimB.dbamp;
			var sig = XFade2.ar(sig_inA, sig_inB, param_Fade, param_Master.dbamp);
			Out.ar(out_Left, sig[0]);
			Out.ar(out_Right, sig[1]);
		}
	)
];

var generateMatrixModulesParams = { |numRows, numCols|
	var result = [
		'FadeTime' -> ControlSpec(0, 1000, 'lin', 0, 5, "ms")
	] ++ numCols.collect { |colIndex|
		numRows.collect { |rowIndex|
				"Gate_"++(colIndex+1)++"_"++(rowIndex+1) -> ControlSpec(0, 1, 'lin', 1, 0, "")
		}
	}.flatten.collect { |assoc| assoc.key.asSymbol -> assoc.value };
	result;
};

var publicAPI = [init, free, newCommand, connectCommand, disconnectCommand, deleteCommand, setCommand, bulksetCommand, newmacroCommand, deletemacroCommand, macrosetCommand, readsampleCommand, tapoutputCommand, tapclearCommand, getTapBus, getVisualBus];

publicAPI;
)
