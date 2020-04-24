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
		var description;
		var experimental;
		var inputs;
		var inputsDocSection;
		var outputs;
		var outputsDocSection;
		var params;
		var paramsDocSection;
		var visuals;
		var visualsDocSection;
		var sampleSlots;
		var sampleSlotsDocSection;

		expandedModuleDef = ();
	
		if (moduleDef[\name].notNil) {
			expandedModuleDef[\name] = moduleDef[\name];
		} {
			Error("Module definition requires a name").throw;
		};

		experimental = moduleDef[\experimental];
		if (experimental.notNil) {
			expandedModuleDef[\experimental] = experimental.value;
		};

		description = moduleDef[\description];
		if (description.notNil) {
			expandedModuleDef[\description] = description.value;
		};

		if (moduleDef[\ugenGraphFunc].notNil) {
			expandedModuleDef[\ugenGraphFunc] = moduleDef[\ugenGraphFunc];
		} {
			Error("Module definition requires an ugenGraphFunc").throw;
		};

		inputs = moduleDef[\inputs];
		if (inputs.notNil) {
			// TODO: validate against ugenGraphFunc
			expandedModuleDef[\inputs] = inputs.value;
		};

		inputsDocSection = moduleDef[\inputsDocSection];
		if (inputsDocSection.notNil) {
			expandedModuleDef[\inputsDocSection] = inputsDocSection.value;
		};

		outputs = moduleDef[\outputs];
		if (outputs.notNil) {
			// TODO: validate against ugenGraphFunc
			expandedModuleDef[\outputs] = outputs.value;
		};

		outputsDocSection = moduleDef[\outputsDocSection];
		if (outputsDocSection.notNil) {
			expandedModuleDef[\outputsDocSection] = outputsDocSection.value;
		};

		params = moduleDef[\params];
		if (params.notNil) {
			// TODO: validate against ugenGraphFunc
			expandedModuleDef[\params] = params.value;
		};

		paramsDocSection = moduleDef[\paramsDocSection];
		if (paramsDocSection.notNil) {
			expandedModuleDef[\paramsDocSection] = paramsDocSection.value;
		};

		visuals = moduleDef[\visuals];
		if (visuals.notNil) {
			// TODO: validate against ugenGraphFunc
			expandedModuleDef[\visuals] = visuals.value;
		};

		visualsDocSection = moduleDef[\visualsDocSection];
		if (visualsDocSection.notNil) {
			expandedModuleDef[\visualsDocSection] = visualsDocSection.value;
		};

		sampleSlots = moduleDef[\sampleSlots];
		if (sampleSlots.notNil) {
			// TODO: validate against ugenGraphFunc
			expandedModuleDef[\sampleSlots] = sampleSlots.value;
		};

		sampleSlotsDocSection = moduleDef[\sampleSlotsDocSection];
		if (sampleSlotsDocSection.notNil) {
			expandedModuleDef[\sampleSlotsDocSection] = sampleSlotsDocSection.value;
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
					bus: bus,
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

		while { consistent and: (i < moduleParameterRefs.size) } {
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

var generateDocsForAllModules = { |self|
	generateDocsForModuleDefs.value(self[\moduleDefs].sortBy(\name));
};

var generateDocsForModuleDefs = { |moduleDefs, includeExperimentalModules=false|
	if (includeExperimentalModules) {
		moduleDefs
	} {
		moduleDefs.reject { |moduleDef| moduleDef[\experimental].asBoolean }
	}.collect { |moduleDef|
		generateDocsForModuleDef.value(moduleDef);
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
var mapModuleParam = { |module, parameter, bus| var moduleDef = module[\moduleDef];
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

var generateDocsForModuleDef = { |moduleDef|
	"###" + moduleDef[\name].asString ++ if (moduleDef[\experimental].asBoolean, " (experimental)", "") ++ "\n" ++
	"\n" ++
	(moduleDef[\description] ? "[insert brief module description here]") ++ "\n" ++
	"\n" ++
	generateInputsDocSectionForModuleDef.value(moduleDef) ++
	generateOutputsDocSectionForModuleDef.value(moduleDef) ++
	generateParametersDocSectionForModuleDef.value(moduleDef) ++
	generateVisualsDocSectionForModuleDef.value(moduleDef) ++
	generateSampleSlotsDocSectionForModuleDef.value(moduleDef)
};

var generateInputsDocSectionForModuleDef = { |moduleDef|
	var spec = getModuleDefSpec.value(moduleDef);
	var inputs = spec[\inputs];
	if (inputs.notEmpty) {
		"- Inputs:" ++
		"\n" ++
		(
			moduleDef[\inputsDocSection] ?
			(
				inputs.collect { |input|
					"\t- " ++ generateInputDocSection.value(moduleDef, input)
				}.join($\n)
			)
		) ++
		"\n"
	} {
		""
	};
};

var generateInputDocSection = { |moduleDef, inputRef|
	var inputDescriptions = getModuleDefInputDescriptions.value(moduleDef);
	if (inputDescriptions.notNil) {
		var description = inputDescriptions[inputRef];
		("`" ++ inputRef.asString ++ "`") ++ if (description.notNil) {": " ++ description } { "" }
	} {
		("`" ++ inputRef.asString ++ "`")
	};
};

var generateOutputsDocSectionForModuleDef = { |moduleDef|
	var spec = getModuleDefSpec.value(moduleDef);
	var outputs = spec[\outputs];
	if (outputs.notEmpty) {
		"- Outputs:" ++
		"\n" ++
		(
			moduleDef[\outputsDocSection] ?
			(
				outputs.collect { |output|
					"\t- " ++ generateOutputDocSection.value(moduleDef, output)
				}.join($\n)
			)
		) ++ "\n"
	} {
		""
	};
};

var generateOutputDocSection = { |moduleDef, outputRef|
	var outputDescriptions = getModuleDefOutputDescriptions.value(moduleDef);
	if (outputDescriptions.notNil) {
		var description = outputDescriptions[outputRef];
		("`" ++ outputRef.asString ++ "`") ++ if (description.notNil) {": " ++ description } { "" }
	} {
		("`" ++ outputRef.asString ++ "`")
	};
};

var generateParametersDocSectionForModuleDef = { |moduleDef|
	var spec = getModuleDefSpec.value(moduleDef);
	var parameters = spec[\parameters];
	if (parameters.notEmpty) {
		"- Parameters:" ++
		"\n" ++
		(
			moduleDef[\paramsDocSection] ?
			(
				parameters.collect { |parameter|
					"\t- " ++ generateParameterDocSection.value(moduleDef, parameter)
				}.join($\n)
			)
		) ++ "\n"
	} {
		""
	};
};

var generateParameterDocSection = { |moduleDef, parameterRef|
	var description = getModuleDefParamDescriptions.value(moduleDef)[parameterRef];
	("`" ++ parameterRef.asString ++ "`") ++ if (description.notNil) {": " ++ description } { "" }
};

var generateVisualsDocSectionForModuleDef = { |moduleDef|
	var spec = getModuleDefSpec.value(moduleDef);
	var visuals = spec[\visuals];
	if (visuals.notEmpty) {
		"- Visuals:" ++
		"\n" ++
		(
			moduleDef[\visualDocs] ?
			(
				visuals.collect { |visual|
					//"\t- `" ++ visual ++ "`" // TODO: include description derived from ControlSpec
					"\t- " ++ generateVisualDocSection.value(moduleDef, visual)
				}.join($\n)
			)
		) ++ "\n"
	} {
		""
	};
};

var generateVisualDocSection = { |moduleDef, visualRef|
	var visualDescriptions = getModuleDefVisualDescriptions.value(moduleDef);
	if (visualDescriptions.notNil) {
		var description = visualDescriptions[visualRef];
		("`" ++ visualRef.asString ++ "`") ++ if (description.notNil) {": " ++ description } { "" }
	} {
		("`" ++ visualRef.asString ++ "`")
	};
};

var generateSampleSlotsDocSectionForModuleDef = { |moduleDef|
	var spec = getModuleDefSpec.value(moduleDef);
	var sampleSlotDetails = spec[\sampleSlots];
	if (sampleSlotDetails.notEmpty) {
		var sampleSlots = sampleSlotDetails.collect { |sampleSlot| // TODO: duct tape fix of bug since getModuleDefSpec \sampleSlots does not return the same as other keys
			sampleSlot.key
		};

		"- Sample Slots:" ++
		"\n" ++
		(
			moduleDef[\sampleSlotDocs] ?
			(
				// TODO: bugs out
				sampleSlots.collect { |sampleSlot|
					"\t- `" ++ sampleSlot ++ "`" // TODO: include description derived from ControlSpec
					// TODO "\t- " ++ generateSampleSlotDocSection.value(moduleDef, sampleSlot)
				}.join($\n)
			)
		) ++ "\n"
	} {
		""
	};
};

var generateSampleSlotDocSection = { |moduleDef, sampleSlotRef|
	var sampleSlotDescriptions = getModuleDefSampleSlotDescriptions.value(moduleDef);
	if (sampleSlotDescriptions.notNil) {
		var description = sampleSlotDescriptions[sampleSlotRef];
		("`" ++ sampleSlotRef.asString ++ "`") ++ if (description.notNil) {": " ++ description } { "" }
	} {
		("`" ++ sampleSlotRef.asString ++ "`")
	};
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
			params.collect { |assoc|
				var assocValue = assoc.value;
				[
					("param_"++assoc.key).asSymbol, // key
					// value ...
					if (assocValue.class == Event) {
						assocValue[\LagTime]
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
			params.collect { |assoc|
				var assocValue = assoc.value;
				[
					("param_"++assoc.key).asSymbol, // key
					// value ...
					if (assocValue.class == ControlSpec) { // TODO: DRY this up
						assocValue
					} {
						// TODO: Event assumed
						assocValue[\Spec]
					}
				]
			}.flatten
		)
	}
};

var getModuleDefParamDescriptions = { |moduleDef|
	var params = getModuleDefParams.value(moduleDef);
	if (params.notNil) {
		IdentityDictionary.newFrom(
			params.collect { |assoc|
				var assocValue = assoc.value;
				[
					assoc.key, // key
					// value ...
					if (assocValue.class == Event) {
						assocValue[\Description]
					} {
						nil
					}
				];
			}.flatten;
		)
	}
};

var getModuleDefInputDescriptions = { |moduleDef|
	var inputs = getModuleDefInputs.value(moduleDef);
	if (inputs.notNil) {
		IdentityDictionary.newFrom(
			inputs.collect { |assoc|
				var assocValue = assoc.value;
				[
					assoc.key, // key
					// value ...
					if (assocValue.class == Event) {
						assocValue[\Description]
					} {
						nil
					}
				];
			}.flatten;
		)
	}
};

var getModuleDefOutputDescriptions = { |moduleDef|
	var outputs = getModuleDefOutputs.value(moduleDef);
	if (outputs.notNil) {
		IdentityDictionary.newFrom(
			outputs.collect { |paramAssoc|
				var assocValue = paramAssoc.value;
				[
					paramAssoc.key, // key
					// value ...
					if (assocValue.class == Event) {
						assocValue[\Description]
					} {
						nil
					}
				];
			}.flatten;
		)
	}
};

var getModuleDefVisualDescriptions = { |moduleDef|
	var visuals = getModuleDefVisuals.value(moduleDef);
	if (visuals.notNil) {
		IdentityDictionary.newFrom(
			visuals.collect { |assoc|
				var assocValue = assoc.value;
				[
					assoc.key, // key
					// value ...
					if (assocValue.class == Event) {
						assocValue[\Description]
					} {
						nil
					}
				];
			}.flatten;
		)
	}
};

var getModuleDefSampleSlotDescriptions = { |moduleDef|
	var sampleSlot = getModuleDefVisuals.value(moduleDef);
	if (sampleSlot.notNil) {
		IdentityDictionary.newFrom(
			sampleSlot.collect { |assoc|
				var assocValue = assoc.value;
				[
					assoc.key, // key
					// value ...
					if (assocValue.class == Event) {
						assocValue[\Description]
					} {
						nil
					}
				];
			}.flatten;
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

var getModuleDefInputs = { |moduleDef|
	moduleDef[\inputs]
};

var getModuleDefOutputs = { |moduleDef|
	moduleDef[\outputs]
};

var getModuleDefVisuals = { |moduleDef|
	moduleDef[\visuals]
};

var getModuleDefSampleSlots = { |moduleDef|
	moduleDef[\sampleSlots]
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
		description: "Stereo sound input",
		outputs: [
			'Left' -> (
				Description: "Audio signal from left R audio input."
			),
			'Right' -> (
				Description: "Audio signal from right R audio input."
			),
		],
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
		description: "Stereo sound output",
		inputs: [
			'Left' -> (
				Description: "Audio signal to left R audio output."
			),
			'Right' -> (
				Description: "Audio signal to right R audio output."
			),
		],
		ugenGraphFunc: {
			|
				in_Left,
				in_Right,
				// TODO param_Gain,
				internal_Out
			|

			var amp = 1; // TODO param_Gain.dbamp;
			Out.ar(internal_Out, [In.ar(in_Left) * amp, In.ar(in_Right) * amp]); // TODO: remove DC to not mess up monitors
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
		description: "4x4 matrix signal router.",
		inputsDocSection: "\t- `In1` ... `In4`: Signal inputs.",
		inputs: { generateMatrixModulesInputs.value(4) },
		outputsDocSection: "\t- `Out1` ... `Out4`: Signal outputs.",
		outputs: { generateMatrixModulesOutputs.value(4) },
		paramsDocSection:
			"\t- `FadeTime`: Fade time in milliseconds (range: `0` - `100000` ms) applied when an input is switched on to or off from an output. Default is `5` ms." ++ "\n" ++
			"\t- `Gate_1_1` ... `Gate_4_4`: Toggles that determine what inputs (first number) are switched on to outputs (second number).",
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
		description: "8x8 matrix signal router.",
		inputsDocSection: "\t- `In1` ... `In8`: Signal inputs.",
		inputs: { generateMatrixModulesInputs.value(8) },
		outputsDocSection: "\t- `Out1` ... `Out8`: Signal outputs.",
		outputs: { generateMatrixModulesOutputs.value(8) },
		paramsDocSection:
			"\t- `FadeTime`: Fade time in milliseconds (range: `0`-`100000` ms) applied when an input is switched on to or off from an output. Default is `5` ms." ++ "\n" ++
			"\t- `Gate_1_1` ... `Gate_8_8`: Toggles that determine what inputs (first number) are switched on to outputs (second number).",
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
		description: "ADSR Envelope.",
		inputs: [
			'Gate' -> (
				Description: "Gate control input. A signal > 0 triggers envelope."
			)
		],
		outputs: [
			'Out' -> (
				Description: "Envelope signal: `0` ... `0.8`."
			)
		],
		params: [
			'Attack' -> (
				Spec: ControlSpec(0.1, 2000, 'exp', 0, 5, "ms"),
				LagTime: 0.1,
				Description: "Attack time. Range `0.1` - `2000` ms. Default is `5`."
			),
			'Decay' -> (
				Spec: ControlSpec(0.1, 8000, 'exp', 0, 200, "ms"),
				LagTime: 0.1,
				Description: "Decay time. Range `0.1` - `8000` ms. Default is `200`."
			),
			'Sustain' -> (
				Spec: ControlSpec(0, 1, 'lin', 0, 0.5, ""),
				LagTime: 0.1,
				Description: "Sustain level `0` - `1.0`. Default is `0.5`."
			),
			'Release' -> (
				Spec: ControlSpec(0.1, 8000, 'exp', 0, 200, "ms"),
				LagTime: 0.1,
				Description: "Release time. Range `0.1` - `8000` ms. Default is `200`."
			),
			'Gate' -> (
				Spec: ControlSpec(0, 1, step: 1, default: 0), // TODO: DRY the gate/reset/boolean specs
				Description: "Scriptable gate. When parameter goes from 0 to a positive value a gate is triggered."
			)
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
		experimental: true,
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
		description: "Simple amplifier with level parameter and exponential or linear gain modulation.",
		inputs: [
			'Exp' -> (
				Description: "Gain modulation control input (logarithmic)."
			),
			'Lin' -> (
				Description: "Gain modulation control input (linear)."
			),
			'In' -> (
				Description: "Input signal to attenuate."
			),
		],
		outputs: [
			'Out' -> (
				Description: "Attenuated signal."
			)
		],
		params: [
			'Level' -> (
				Spec: \unipolar.asSpec,
				LagTime: 0.1,
				Description: "Amplifier level `0` - `1.0`."
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
		description: "Amplifier with two inputs, level parameter and variable exponential or linear gain modulation.",
		inputs: [
			'GainModulation' -> (
				Description: "Control input for gain modulation."
			),
			'In1' -> (
				Description: "Audio input 1."
			),
			'In2' -> (
				Description: "Audio input 2."
			),
		],
		outputs: [
			'Out' -> (
				Description: "Attenuated signal."
			)
		],
		params: [
			'Gain' -> (
				Spec: \unipolar.asSpec,
				LagTime: 0.1,
				Description: "Initial gain `0` - `1.0`."
			),
			'GainModulation' -> (
				Spec: \bipolar.asSpec,
				LagTime: 0.1,
				Description: "Gain modulation amount `0` - `1.0`."
			),
			'In1' -> (
				Spec: \unipolar.asSpec,
				LagTime: 0.1,
				Description: "Audio input 1 level `0` - `1.0`."
			),
			'In2' -> (
				Spec: \unipolar.asSpec,
				LagTime: 0.1,
				Description: "Audio input 2 level `0` - `1.0`."
			),
			'Out' -> (
				Spec: \unipolar.asSpec,
				LagTime: 0.1,
				Description: "Audio output level `0` - `1.0`."
			),
			'Mode' -> (
				Spec: ControlSpec.new(0, 1, 'lin', 1, 0),
				Description: "`0` or `1` representing linear or exponential gain modulation."
			)
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
		description: "Resonant bandpass SVF filter.",
		inputs: [
			'In' -> (
				Description: "Audio input."
			),
			'FM' -> (
				Description: "Control input for frequency modulation."
			),
			'ResonanceModulation' -> (
				Description: "Control input for resonance modulation."
			),
		],
		outputs: [
			'Out' -> (
				Description: "Filtered audio signal."
			)
		],
		params: [
			'AudioLevel' -> (
				Spec: \amp.asSpec.copy.default_(1), // TODO: updated
				LagTime: 0.1,
				Description: "Audio level `0` ... `1.0`. Default is `1`."
			),
			'Frequency' -> (
				Spec: \widefreq.asSpec,
				LagTime: 0.1,
				Description: "Cutoff frequency `0.1` ... `20000` Hz. Default is `440` Hz."
			),
			'Resonance' -> (
				Spec: \unipolar.asSpec,
				LagTime: 0.1,
				Description: "Resonance `0` ... `1.0`. Default is `0`."
			),
			'FM' -> (
				Spec: \bipolar.asSpec,
				LagTime: 0.1,
				Description: "Frequency modulation amount `-1.0` ... `1.0`."
			),
			'ResonanceModulation' -> (
				Spec: \bipolar.asSpec,
				LagTime: 0.1,
				Description: "Resonance modulation amount `-1.0` ... `1.0`."
			),
		],
		visuals: [
			'Frequency' -> (
				Spec: \widefreq.asSpec,
				Description: "Cutoff frequency `0.1` ... `20000` Hz."
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
		description: "Resonant bandreject (Notch) SVF filter.",
		inputs: [
			'In' -> (
				Description: "Audio input."
			),
			'FM' -> (
				Description: "Control input for frequency modulation."
			),
			'ResonanceModulation' -> (
				Description: "Control input for resonance modulation."
			),
		],
		outputs: [
			'Out' -> (
				Description: "Filtered audio signal."
			)
		],
		params: [
			'AudioLevel' -> (
				Spec: \amp.asSpec.copy.default_(1), // TODO: updated
				LagTime: 0.1,
				Description: "Audio level `0` ... `1.0`. Default is `1`."
			),
			'Frequency' -> (
				Spec: \widefreq.asSpec,
				LagTime: 0.1,
				Description: "Cutoff frequency `0.1` ... `20000` Hz. Default is `440` Hz."
			),
			'Resonance' -> (
				Spec: \unipolar.asSpec,
				LagTime: 0.1,
				Description: "Resonance `0` ... `1.0`. Default is `0`."
			),
			'FM' -> (
				Spec: \bipolar.asSpec,
				LagTime: 0.1,
				Description: "Frequency modulation amount `-1.0` ... `1.0`."
			),
			'ResonanceModulation' -> (
				Spec: \bipolar.asSpec,
				LagTime: 0.1,
				Description: "Resonance modulation amount `-1.0` ... `1.0`."
			),
		],
		visuals: [
			'Frequency' -> (
				Spec: \widefreq.asSpec,
				Description: "Cutoff frequency `0.1` ... `20000` Hz."
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
		// status: untested
		name: 'Comp2',
		experimental: true,
		inputs: [
			'Left' -> (
				Description: "Left audio input"
			),
			'Right' -> (
				Description: "Right audio input."
			),
			'SideChain' -> (
				Description: "Side chain control input."
			),
		],
		outputs: [
			'Left' -> (
				Description: "Left compressed audio signal."
			),
			'Right' -> (
				Description: "Right compressed audio signal."
			),
		],
		params: [
			'Threshold' -> (
				Spec: \db.asSpec.copy.default_(-10),
				Description: "Treshold."
			),
			'Attack' -> (
				Spec: ControlSpec(0.1, 250, 'exp', 0, 10, "ms"),
				Description: "Attack time."
			),
			'Release' -> (
				Spec: ControlSpec(0.1, 1000, 'exp', 0, 100, "ms"),
				Description: "Release time."
			),
			'Ratio' -> (
				Spec: ControlSpec(0, 20, default: 3),
				Description: "Compression ratio."
			),
			'MakeUp' -> (
				Spec: \db.asSpec.copy.maxval_(20).default_(0),
				Description: "Make up level."
			),
		],
		visuals: [
			'GR' -> (
				Description: "Gain reduction."
			),
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
		description: "Mixer suited for audio signals.",
		inputsDocSection: "\t- `In1` ... `In4`: Audio inputs 1 ... 4.",
		inputs: {
			4.collect { |index|
				("In"++(index+1)) -> (
					Description: "Audio input" + (index+1) ++ "."
				)
			};
		},
		outputs: [
			'Out' -> (
				Description: "Mixed signal."
			),
		],
		paramsDocSection:
			"\t- `In1` ... `In4`: Audio input 1 ... 4 levels TODO: range/spec." ++ "\n" ++
			"\t- `Out`: Output level TODO: range/spec.",
		params: {
			4.collect { |index|
				("In"++(index+1)).asSymbol -> (
					Spec: \db.asSpec,
					LagTime: 0,
					Description: "Audio input" + (index+1) + "level TODO: range/spec."
				)
			} ++
			[
				'Out' -> (
					Spec: \db.asSpec,
					LagTime: 0,
					Description: "Output level TODO: range/spec."
				)
			]
		},
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
		// Status: tested
		name: 'Decimate',
		experimental: true,
		description: "Sample rate and bit depth reducer.",
		inputs: [
			'In' -> (
				Description: "Audio input."
			),
			// TODO: call this RateModulation, DepthModulation, SmoothModulation?
			'Rate' -> (
				Description: "TODO."
			),
			'Depth' -> (
				Description: "TODO."
			),
			'Smooth' -> (
				Description: "TODO."
			),
		],
		outputs: [
			'Out' -> (
				Description: "Reduced signal."
			),
		],
		params: [
			'Rate' -> (
				Spec: \unipolar.asSpec,
				LagTime: 0.1,
				Description: "TODO."
			),
			'Depth' -> (
				Spec: \unipolar.asSpec,
				LagTime: 0.1,
				Description: "TODO."
			),
			'Smooth' -> (
				Spec: \unipolar.asSpec,
				LagTime: 0.1,
				Description: "TODO."
			),
			'RateModulation' -> (
				Spec: \unipolar.asSpec,
				LagTime: 0.1,
				Description: "TODO."
			),
			'DepthModulation' -> (
				Spec: \unipolar.asSpec,
				LagTime: 0.1,
				Description: "TODO."
			),
			'SmoothModulation' -> (
				Spec: \unipolar.asSpec,
				LagTime: 0.1,
				Description: "TODO."
			)
		],
		ugenGraphFunc: {
			|
				in_In,
				in_Rate,
				in_Depth,
				in_Smooth
				out_Out,
				param_Rate,
				param_Depth,
				param_Smooth,
				param_RateModulation,
				param_DepthModulation,
				param_SmoothModulation
			|

			var sig_In = In.ar(in_In);
			var sig_Rate = In.ar(in_Rate);
			var sig_Depth = In.ar(in_Rate);
			var sig_Smooth = In.ar(in_Rate);

			// TODO: 48000 should be SampleRate.ir?
			Out.ar(out_Out,
			       SmoothDecimator.ar(Decimator.ar(sig_In, 48000, (param_Depth + (sig_Depth * param_Depth)) * 24), (param_Rate + (sig_Rate * param_RateModulation)) * 48000, param_Smooth + (sig_Smooth * param_SmoothModulation))
			);
		}
	),
	(
		// Status: partly tested. TODO: what modulation input range should be used?
		name: 'Delay',
		description: "Delay line.",
		inputs: [
			'In' -> (
				Description: "Audio input."
			),
			'DelayTimeModulation' -> (
				Description: "Control signal for delay time modulation."
			)
		],
		outputs: [
			'Out' -> (
				Description: "Delayed signal."
			),
		],
		params: [
			'DelayTime' -> (
				Spec: ControlSpec(0.1, 5000, 'exp', 0, 300, "ms"),
				LagTime: 0.25,
				Description: "Delay time `0.1` ... `5000` ms."
			),
			'DelayTimeModulation' -> (
				Spec: \bipolar.asSpec,
				LagTime: 0.1,
				Description: "Delay time modulation amount."
			),
		],
		visuals: [
			'DelayTime' -> (
				Spec: ControlSpec(0.1, 5000, 'exp', 0, 300, "ms"),
				Description: "Delay time."
			),
		],
		ugenGraphFunc: {
			|
				in_In,
				in_DelayTimeModulation,
				out_Out,
				param_DelayTime,
				param_DelayTimeModulation,
				visual_DelayTime
			|

			var sig_In = In.ar(in_In);
			var sig_DelayTimeModulation = In.ar(in_DelayTimeModulation);

			var delayTimeSpec = ControlSpec(0.1, 5000, 'exp', 0, 300, "ms");

			var delayTimeMs = delayTimeSpec.map(
				delayTimeSpec.unmap(param_DelayTime) + (sig_DelayTimeModulation * param_DelayTimeModulation)
			);

			var delayed = DelayC.ar(sig_In, maxdelaytime: delayTimeSpec.maxval/1000, delaytime: delayTimeMs/1000); // TODO: ControlDur.ir minimum

			Out.ar(out_Out, delayed);
			Out.kr(visual_DelayTime, delayTimeMs);
		}
	),
	(
		// Status: tested
		name: 'EQBP',
		description: "Non-resonant, variable width bandpass filter.",
		params: [
			'Frequency' -> (
				Spec: \widefreq.asSpec,
				LagTime: 0.1,
				Description: "TODO"
			),
			'Bandwidth' -> (
				Spec: ControlSpec.new(0, 10),
				LagTime: 0.1,
				Description: "TODO"
			),
			'FM' -> (
				Spec: \bipolar.asSpec,
				LagTime: 0.01,
				Description: "TODO"
			),
			'BandwidthModulation' -> (
				Spec: \bipolar.asSpec,
				LagTime: 0.01,
				Description: "TODO"
			),
		],
		ugenGraphFunc: {
			|
				in_In,
				in_FM,
				in_BandwidthModulation,
				out_Out,
				param_Frequency,
				param_Bandwidth,
				param_FM,
				param_BandwidthModulation
			|

			var sig_In = In.ar(in_In);
			var sig_FM = In.ar(in_FM);
			var sig_BandwidthModulation = In.ar(in_BandwidthModulation);

			var frequencySpec = \widefreq.asSpec;
			var bandwidthSpec = ControlSpec.new(0, 10);

			var frequency = frequencySpec.map(frequencySpec.unmap(param_Frequency) + (sig_FM * param_FM));
			var bandwidth = bandwidthSpec.map(bandwidthSpec.unmap(param_Bandwidth) + (sig_BandwidthModulation * param_BandwidthModulation));

			Out.ar(
				out_Out,
				BBandPass.ar(
					sig_In,
					frequency,
					bandwidth,
				)
			);
		}
	),
	(
		name: 'EnvF',
		experimental: true,
		description: "Envelope follower.",
		inputs: [
			'In' -> (
				Description: "Input signal"
			)
		],
		outputs: [
			'Env' -> (
				Description: "Envelope follower control output signal."
			),
			'Gate' -> (
				Description: "Gte control output signal."
			)
		],
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
			'Attack' -> (
				Spec: ControlSpec(0.1, 2000, 'exp', 0, 100, "ms"),
				Description: "Envelope follower attack time."
			),
			'Decay' -> (
				Spec: ControlSpec(0.1, 8000, 'exp', 0, 200, "ms"),
				Description: "Envelope follower decay time."
			),
			'Sensitivity' -> (
				Spec: ControlSpec(0, 1, default: 0.5),
				Description: "Envelope follower sensitivity."
			),
			'Threshold' -> (
				Spec: ControlSpec(0, 1, default: 0.5),
				Description: "Envelope follower threshold."
			),
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
		experimental: true,
		description: "FM synthesis voice.",
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
		description: "CV/Gate like thing.",
		outputs: [
			'Frequency' -> (
				Description: "Frequency control signal."
			),
			'Gate' -> (
				Description: "Gate control signal."
			),
			'Trig' -> (
				Description: "Trig control signal."
			)
		],
		params: [
			'Frequency' -> (
				Spec: \freq.asSpec,
				Description: "Frequency parameter."
			),
			'Gate' -> (
				Spec: ControlSpec(0, 1, step: 1, default: 0), // TODO: DRY the gate/reset/boolean specs
				Description: "Gate parameter."
			)
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
		description: "Frequency shifter.",
		inputs: [
			'Left' -> (
				Description: "Left audio input."
			),
			'Right' -> (
				Description: "Right audio input."
			),
			'FM' -> (
				Description: "Control signal for frequency shift modulation."
			)
		],
		outputs: [
			'Left' -> (
				Description: "Left shifted signal."
			),
			'Right' -> (
				Description: "Right shifted signal."
			),
		],
		params: [
			'Frequency' -> (
				Spec: ControlSpec(-2000, 2000, 'lin', 0, 0, "Hz"),
				LagTime: 0.1,
				Description: "Frequency shift. `-2000` Hz ... `+2000` Hz."
			),
			'FM' -> (
				Spec: \bipolar.asSpec,
				LagTime: 0.1,
				Description: "Frequency modulation amount. `-1.0` ... `+1.0`."
			),
		],
		visuals: [
			'Frequency' -> (
				Spec: ControlSpec(-2000, 2000, 'lin', 0, 0, "Hz"),
				Description: "Frequency shift."
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
				param_FM,
				visual_Frequency
			|

			var frequencySpec = ControlSpec(-2000, 2000, 'lin', 0, 0, "Hz");

			var sig_Left = In.ar(in_Left);
			var sig_Right = In.ar(in_Right);
			var sig_FM = In.ar(in_FM);

			var frequency = frequencySpec.constrain(param_Frequency + (sig_FM * 2000 * param_FM));
			var shifted = FreqShift.ar([sig_Left, sig_Right], frequency);

			Out.ar(out_Left, shifted[0]);
			Out.ar(out_Right, shifted[1]);
			Out.kr(visual_Frequency, frequency);
		}
	),
	(
		// Status: tested
		name: 'HPFilter',
		description: "Resonant highpass SVF filter.",
		inputs: [
			'In' -> (
				Description: "Audio input."
			),
			'FM' -> (
				Description: "Control input for frequency modulation."
			),
			'ResonanceModulation' -> (
				Description: "Control input for resonance modulation."
			),
		],
		outputs: [
			'Out' -> (
				Description: "Filtered audio signal."
			)
		],
		params: [
			'AudioLevel' -> (
				Spec: \amp.asSpec.copy.default_(1), // TODO: updated
				LagTime: 0.1,
				Description: "Audio level `0` ... `1.0`. Default is `1`."
			),
			'Frequency' -> (
				Spec: \widefreq.asSpec,
				LagTime: 0.1,
				Description: "Cutoff frequency `0.1` ... `20000` Hz. Default is `440` Hz."
			),
			'Resonance' -> (
				Spec: \unipolar.asSpec,
				LagTime: 0.1,
				Description: "Resonance `0` ... `1.0`. Default is `0`."
			),
			'FM' -> (
				Spec: \bipolar.asSpec,
				LagTime: 0.1,
				Description: "Frequency modulation amount `-1.0` ... `1.0`."
			),
			'ResonanceModulation' -> (
				Spec: \bipolar.asSpec,
				LagTime: 0.1,
				Description: "Resonance modulation amount `-1.0` ... `1.0`."
			),
		],
		visuals: [
			'Frequency' -> (
				Spec: \widefreq.asSpec,
				Description: "Cutoff frequency `0.1` ... `20000` Hz."
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
		description: "Mixer suited for control signals.",
		inputsDocSection: "\t- `In1` ... `In4`: Audio inputs 1 ... 4.",
		inputs: {
			4.collect { |index|
				("In"++(index+1)) -> (
					Description: "Audio input" + (index+1) ++ "."
				)
			};
		},
		outputs: [
			'Out' -> (
				Description: "Mixed signal."
			),
		],
		paramsDocSection:
			"\t- `In1` ... `In4`: Audio input 1 ... 4 levels TODO: range/spec." ++ "\n" ++
			"\t- `Out`: Output level TODO: range/spec.",
		params: {
			4.collect { |index|
				("In"++(index+1)).asSymbol -> (
					Spec: \unipolar.asSpec,
					LagTime: 0.1,
					Description: "Audio input" + (index+1) + "level TODO: range/spec."
				)
			} ++
			[
				'Out' -> (
					Spec: \unipolar.asSpec,
					LagTime: 0.1,
					Description: "Output level TODO: range/spec."
				)
			]
		},
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
		description: "Resonant lowpass SVF filter.",
		inputs: [
			'In' -> (
				Description: "Audio input."
			),
			'FM' -> (
				Description: "Control input for frequency modulation."
			),
			'ResonanceModulation' -> (
				Description: "Control input for resonance modulation."
			),
		],
		outputs: [
			'Out' -> (
				Description: "Filtered audio signal."
			)
		],
		params: [
			'AudioLevel' -> (
				Spec: \amp.asSpec.copy.default_(1), // TODO: updated
				LagTime: 0.1,
				Description: "Audio level `0` ... `1.0`. Default is `1`."
			),
			'Frequency' -> (
				Spec: \widefreq.asSpec,
				LagTime: 0.1,
				Description: "Cutoff frequency `0.1` ... `20000` Hz. Default is `440` Hz."
			),
			'Resonance' -> (
				Spec: \unipolar.asSpec,
				LagTime: 0.1,
				Description: "Resonance `0` ... `1.0`. Default is `0`."
			),
			'FM' -> (
				Spec: \bipolar.asSpec,
				LagTime: 0.1,
				Description: "Frequency modulation amount `-1.0` ... `1.0`."
			),
			'ResonanceModulation' -> (
				Spec: \bipolar.asSpec,
				LagTime: 0.1,
				Description: "Resonance modulation amount `-1.0` ... `1.0`."
			),
		],
		visuals: [
			'Frequency' -> (
				Spec: \widefreq.asSpec,
				Description: "Cutoff frequency `0.1` ... `20000` Hz."
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
		description: "Lowpass ladder filter.",
		inputs: [
			'In' -> (
				Description: "Audio input."
			),
			'FM' -> (
				Description: "Control input for frequency modulation."
			),
			'ResonanceModulation' -> (
				Description: "Control input for resonance modulation."
			),
		],
		outputs: [
			'Out' -> (
				Description: "Filtered audio signal."
			)
		],
		params: [
			'Frequency' -> (
				Spec: \widefreq.asSpec,
				LagTime: 0.1,
				Description: "Cutoff frequency `0.1` ... `20000` Hz. Default is `440` Hz."
			),
			'Resonance' -> (
				Spec: \unipolar.asSpec,
				LagTime: 0.1,
				Description: "Resonance `0` ... `1.0`. Default is `0`."
			),
			'FM' -> (
				Spec: \bipolar.asSpec,
				LagTime: 0.1,
				Description: "Frequency modulation amount `-1.0` ... `1.0`."
			),
			'ResonanceModulation' -> (
				Spec: \bipolar.asSpec,
				LagTime: 0.1,
				Description: "Resonance modulation amount `-1.0` ... `1.0`."
			),
		],
		visuals: [
			'Frequency' -> (
				Spec: \widefreq.asSpec,
				Description: "Cutoff frequency `0.1` ... `20000` Hz."
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
		description: "Audio fader with db gain control and mute.",
		inputs: [
			'In' -> (
				Description: "Audio input."
			)
		],
		outputs: [
			'Out' -> (
				Description: "Attenuated audio signal."
			)
		],
		params: [
			'Gain' -> (
				Spec: \db.asSpec.copy.maxval_(12).default_(0),
				// TODO LagTime: 0.1
				Description: "Attenuation control. `-inf` ... `+12` dB."
			),
			'Mute' -> (
				Spec: ControlSpec(0, 1, 'lin', 1, 0, ""),
				// TODO LagTime: 0.1
				Description: "If `1` signal is muted, otherwise not."
			),
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
		description: "Resonant SVF multimode filter.",
		inputs: [
			'In' -> (
				Description: "Audio input."
			),
			'FM' -> (
				Description: "Control input for frequency modulation."
			),
			'ResonanceModulation' -> (
				Description: "Control input for resonance modulation."
			),
		],
		outputs: [
			'Notch' -> (
				Description: "Band-reject filtered audio signal."
			),
			'Highpass' -> (
				Description: "Highpass filtered audio signal."
			),
			'Bandpass' -> (
				Description: "Bandpass filtered audio signal."
			),
			'Lowpass' -> (
				Description: "Lowpass filtered audio signal."
			),
		],
		params: [
			'AudioLevel' -> (
				Spec: \amp.asSpec.copy.default_(1), // TODO: updated
				LagTime: 0.1,
				Description: "Audio level `0` ... `1.0`. Default is `1`."
			),
			'Frequency' -> (
				Spec: \widefreq.asSpec,
				LagTime: 0.1,
				Description: "Cutoff frequency `0.1` ... `20000` Hz. Default is `440` Hz."
			),
			'Resonance' -> (
				Spec: \unipolar.asSpec,
				LagTime: 0.1,
				Description: "Resonance `0` ... `1.0`. Default is `0`."
			),
			'FM' -> (
				Spec: \bipolar.asSpec,
				LagTime: 0.1,
				Description: "Frequency modulation amount `-1.0` ... `1.0`."
			),
			'ResonanceModulation' -> (
				Spec: \bipolar.asSpec,
				LagTime: 0.1,
				Description: "Resonance modulation amount `-1.0` ... `1.0`."
			),
		],
		visuals: [
			'Frequency' -> (
				Spec: \widefreq.asSpec,
				Description: "Cutoff frequency `0.1` ... `20000` Hz."
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
		description: "LFO featuring multiple waveforms.",
		inputs: [
			'Reset' -> (
				Description: "Audio rate reset trigger: when signal is changed from 0 to 1 the LFO is retriggered.",
				Range: [0, 1]
			),
		],
		outputs: [
			'InvSaw' -> (
				Description: "Inverted saw signal output.",
				Range: [-0.25, 0.25]
			),
			'Saw' -> (
				Description: "Saw signal output.",
				Range: [-0.25, 0.25]
			),
			'Sine' -> (
				Description: "Sine signal output.",
				Range: [-0.25, 0.25]
			),
			'Triangle' -> (
				Description: "Triangle signal output.",
				Range: [-0.25, 0.25]
			),
			'Pulse' -> (
				Description: "Pulse signal output.",
				Range: [-0.25, 0.25]
			),
		],
		params: [
			'Frequency' -> (
				Description: "LFO Frequency `0.01` Hz ... `50` Hz.",
				Spec: ControlSpec(0.01, 50, 'exp', 0, 1, "Hz"),
				LagTime: 0.01
			),
			'Reset' -> (
				Description: "Manual LFO reset trigger.",
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
		description: "Oscillator featuring multiple waveforms.",
		inputs: [
			'FM' -> (
				Description: "Control signal for frequency modulation."
			),
			'PWM' -> (
				Description: "Control signal for pulse width modulation."
			)
		],
		outputs: [
			'Sine' -> (
				Description: "Sine wave oscillator output."
			),
			'Triangle' -> (
				Description: "Triangle wave oscillator output."
			),
			'Saw' -> (
				Description: "Saw wave oscillator output."
			),
			'Pulse' -> (
				Description: "Pulse wave oscillator output."
			),
		],
		params: [
			'Range' -> (
				Spec: ControlSpec.new(-2, 2, 'lin', 1, 0),
				LagTime: 0.01,
				Description: "`-2` ... `+2` octaves."
			),
			'Tune' -> (
				Spec: ControlSpec.new(-600, 600, 'lin', 0, 0, "cents"),
				LagTime: 0.01,
				Description: "`-1200` ... `+1200` cents."
			),
			'PulseWidth' -> (
				Spec: \unipolar.asSpec.copy.default_(0.5),
				LagTime: 0.01,
				Description: "Pulse oscillator pulse width."
			),
			'FM' -> (
				Spec: \unipolar.asSpec, // TODO: bipolar?
				LagTime: 0.01,
				Description: "Frequency modulation amount."
			),
			'PWM' -> (
				Spec: \unipolar.asSpec,
				LagTime: 0.01,
				Description: "Pulse width modulation amount."
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
		// Status: experimental
		// Inspiration from A-110 (but no Sync input)
		name: 'MultiOscExp',
		experimental: true,
		description: "Oscillator featuring multiple waveforms (w/ linear FM features).",
		inputs: [
			'FM' -> (
				Description: "Control signal for frequency modulation."
			),
			'LinFM' -> (
				Description: "Control signal for linear frequency modulation."
			),
			'PWM' -> (
				Description: "Control signal for pulse width modulation."
			),
/*
	TODO
			'PM' -> (
				Description: "Control signal for phase modulation"
			),
*/
		],
		outputs: [
			'Sine' -> (
				Description: "Sine wave oscillator output."
			),
			'Triangle' -> (
				Description: "Triangle wave oscillator output."
			),
			'Saw' -> (
				Description: "Saw wave oscillator output."
			),
			'Pulse' -> (
				Description: "Pulse wave oscillator output."
			),
		],
		params: [
			'Range' -> (
				Spec: ControlSpec.new(-2, 2, 'lin', 1, 0),
				LagTime: 0.01,
				Description: "`-2` ... `+2` octaves."
			),
			'Tune' -> (
				Spec: ControlSpec.new(-600, 600, 'lin', 0, 0, "cents"),
				LagTime: 0.01,
				Description: "`-1200` ... `+1200` cents."
			),
			'PulseWidth' -> (
				Spec: \unipolar.asSpec.copy.default_(0.5),
				LagTime: 0.01,
				Description: "Pulse oscillator pulse width."
			),
			'FM' -> (
				Spec: \unipolar.asSpec, // TODO: bipolar?
				LagTime: 0.01,
				Description: "Frequency modulation amount."
			),
			'LinFM' -> (
				Spec: ControlSpec.new(0, 10000, 'lin', nil, 0, "Hz"),
				LagTime: 0.2,
				Description: "Linear frequency modulation amount."
			),
/*
	TODO
			'PM' -> (
				Spec: ControlSpec.new(0, 5, 'lin', 0.01, 0, ""),
				LagTime: 0.2
			),
*/
			'PWM' -> (
				Spec: \unipolar.asSpec,
				LagTime: 0.01,
				Description: "Pulse width modulation amount."
			),
		],
		ugenGraphFunc: {
			|
				in_FM,
				in_LinFM,
				in_PWM,
				out_Sine,
				out_Triangle,
				out_Saw,
				out_Pulse,
				param_Range,
				param_Tune,
				param_FM,
				param_LinFM,
				param_PulseWidth,
				param_PWM
			|

			var sig_FM = In.ar(in_FM);
			var sig_LinFM = In.ar(in_LinFM);
			var sig_PWM = In.ar(in_PWM);

			var fullRange = ControlSpec(12.midicps, 120.midicps);

			var frequency = fullRange.constrain(
				( // TODO: optimization - implement overridable set handlers and do this calculation in sclang rather than server
					3 +
					param_Range +
					(param_Tune / 1200) +
					(sig_FM * 10 * param_FM) // 0.1 = 1 oct
				).octcps + (sig_LinFM * param_LinFM)
			);

			var pulseWidth = (
				param_PulseWidth + (sig_PWM * param_PWM)
			).clip(0, 1);

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
		// Status: tested, TODO: make a script
		name: 'Noise',
		description: "White noise generator.",
		outputs: [
			'Out' -> (
				Description: "Noise signal."
			)
		],
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
		// Status: not tested
		name: 'OGain',
		description: "8-in/8-out audio fader with db gain control and mute.",
		inputsDocSection: "\t- `In1` ... `In8`: Audio inputs.",
		inputs: {
			8.collect { |index|
				("In"++(index+1)).asSymbol -> (
					Description: "Audio input" + (index+1) ++ "."
				)
			};
		},
		outputsDocSection: "\t- `Out1` ... `Out8`: Attenuated audio signal outputs.",
		outputs: {
			8.collect { |index|
				("Out"++(index+1)).asSymbol -> (
					Description: "Attenuated audio signal output" + (index+1) ++ "."
				)
			};
		},
		params: [
			'Gain' -> (
				Spec: \db.asSpec.copy.maxval_(12).default_(0),
				// TODO LagTime: 0.1
				Description: "Attenuation control. `-inf` ... `+12` dB."
			),
			'Mute' -> (
				Spec: ControlSpec(0, 1, 'lin', 1, 0, ""),
				// TODO LagTime: 0.1
				Description: "If `1` signal is muted, otherwise not."
			),
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
		name: 'Pan',
		description: "Stereo panner with monophonic input.",
		inputs: [
			'In' -> (
				Description: "Mono audio signal."
			),
			'PositionModulation' -> (
				Description: "Right audio signal."
			),
		],
		outputs: [
			'Left' -> (
				Description: "Left audio signal."
			),
			'Right' -> (
				Description: "Right audio signal."
			),
		],
		params: [
			'Position' -> (
				Spec: \bipolar.asSpec,
				LagTime: 0.1,
				Description: "Pan position `-1.0` ... `1.0` referring to left ... right panning."
			),
			'PositionModulation' -> (
				Spec: \bipolar.asSpec,
				LagTime: 0.1,
				Description: "Pan position modulation amount `-1.0` ... `1.0`."
			),
		],
		ugenGraphFunc: {
			|
				in_In,
				in_PositionModulation,
				out_Left,
				out_Right,
				param_Position,
				param_PositionModulation
			|

			var sig_In = In.ar(in_In);
			var sig_PositionModulation = In.ar(in_PositionModulation);

			var sig = Pan2.ar(sig_In, param_Position + (sig_PositionModulation * param_PositionModulation));
			Out.ar(out_Left, sig[0]);
			Out.ar(out_Right, sig[1]);
		}
	),
	(
		// Status: tested
		// TODO: or just extend LinMixer, make it bipolar?
		name: 'PolMixer',
		experimental: true,
		inputsDocSection: "\t- `In1` ... `In4`: Audio inputs 1 ... 4",
		inputs: {
			4.collect { |index|
				("In"++(index+1)).asSymbol -> (
					Description: "Audio input" + (index+1) ++ "."
				)
			};
		},
		outputs: [
			'Out' -> (
				Description: "Mixed signal."
			),
		],
		paramsDocSection:
			"\t- `In1` ... `In4`: Audio input 1 ... 4 levels TODO: range/spec." ++ "\n" ++
			"\t- `Out`: Output level TODO: range/spec.",
		params: {
			4.collect { |index|
				("In"++(index+1)).asSymbol -> (
					Spec: \bipolar.asSpec,
					LagTime: 0.1,
					Description: "Audio input" + (index+1) + "level TODO: range/spec."
				)
			} ++
			[
				'Out' -> ( // TODO: 0 is default, is that right?
					Spec: \unipolar.asSpec,
					LagTime: 0.1,
					Description: "Output level TODO: range/spec."
				)
			]
		},
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
		name: 'PNoise',
		description: "Pink noise generator.",
		outputs: [
			'Out' -> (
				Description: "Noise signal."
			)
		],
		ugenGraphFunc: {
			|
				out_Out
			|

			Out.ar(
				out_Out,
				PinkNoise.ar
			);
		}
	),
	(
		// Status: partly tested. TODO: review modulation input mapping
		name: 'PShift',
		description: "Pitch shifter.",
		inputs: [
			'Left' -> (
				Description: "Left audio signal."
			),
			'Right' -> (
				Description: "Right audio signal."
			),
			'PitchRatioModulation' -> (
				Description: "Pitch ratio modulation amount."
			),
			'PitchDispersionModulation' -> (
				Description: "Pitch dispersion modulation amount."
			),
			'TimeDispersionModulation' -> (
				Description: "Time dispersion modulation amount."
			),
		],
		outputs: [
			'Left' -> (
				Description: "Left processed audio signal."
			),
			'Right' -> (
				Description: "Right processed audio signal."
			),
		],
		params: [
			'PitchRatio' -> (
				Spec: ControlSpec(0, 4, default: 1),
				LagTime: 0.1,
				Description: "Pitch ratio: `0` ... `4`. Default is `1`."
			),
			'PitchDispersion' -> (
				Spec: ControlSpec(0, 4),
				LagTime: 0.1,
				Description: "Pitch dispersion: `0` ... `4`. Default is `0`."
			),
			'TimeDispersion' -> (
				Spec: ControlSpec(0, 1),
				LagTime: 0.1,
				Description: "Time dispersion: `0` ... `1`. Default is `0`."
			),
			'PitchRatioModulation' -> (
				Spec: \bipolar.asSpec,
				Description: "Pitch ratio modulation amount: `-1` ... `1`."
			),
			'PitchDispersionModulation' -> (
				Spec: \bipolar.asSpec,
				Description: "Pitch dispersion modulation amount: `-1` ... `1`."
			),
			'TimeDispersionModulation' -> (
				Spec: \bipolar.asSpec,
				Description: "Time dispersion modulation amount: `-1` ... `1`."
			),
		],
		visuals: [
			'PitchRatio' -> (
				Spec: ControlSpec(0, 4, default: 1),
				Description: "Time dispersion modulation amount: `-1` ... `1`."
			),
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
				param_TimeDispersionModulation,
				visual_PitchRatio
				// TODO: visual_PitchDispersion
				// TODO: visual_TimeDispersion
			|

			var pitchRatioSpec = ControlSpec(0, 4, default: 1);
			var pitchDispersionSpec = ControlSpec(0, 4);
			var timeDispersionSpec = ControlSpec(0, 1);

			var sig_Left = In.ar(in_Left);
			var sig_Right = In.ar(in_Right);
			var sig_PitchRatioModulation = In.ar(in_PitchRatioModulation);
			var sig_PitchDispersionModulation = In.ar(in_PitchDispersionModulation);
			var sig_TimeDispersionModulation = In.ar(in_TimeDispersionModulation);

			var pitchRatio = pitchRatioSpec.map(
				pitchRatioSpec.unmap(param_PitchRatio) +
				(sig_PitchRatioModulation * param_PitchRatioModulation)
			);

			var shifted = PitchShift.ar(
				[sig_Left, sig_Right],
				0.2,
				pitchRatio,
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
			Out.kr(visual_PitchRatio, pitchRatio);
		}
	),
	(
		// Status: tested
		name: 'PulseOsc',
		description: "Pulse/square oscillator with pulse width control.",
		inputs: [
			'FM' -> (
				Description: "Control signal for frequency modulation."
			),
			'PWM' -> (
				Description: "Control signal for pulse width modulation."
			)
		],
		outputs: [
			'Out' -> (
				Description: "Pulse wave oscillator output."
			),
		],
		params: [
			'Range' -> (
				Spec: ControlSpec.new(-2, 2, 'lin', 1, 0),
				LagTime: 0.01,
				Description: "`-2` ... `+2` octaves."
			),
			'Tune' -> (
				Spec: ControlSpec.new(-600, 600, 'lin', 0, 0, "cents"),
				LagTime: 0.01,
				Description: "`-1200` ... `+1200` cents."
			),
			'PulseWidth' -> (
				Spec: \unipolar.asSpec.copy.default_(0.5),
				LagTime: 0.01,
				Description: "Pulse oscillator Pulse width."
			),
			'FM' -> (
				Spec: \unipolar.asSpec, // TODO: bipolar?
				LagTime: 0.01,
				Description: "Frequency modulation amount."
			),
			'PWM' -> (
				Spec: \unipolar.asSpec.copy.default_(0.4),
				LagTime: 0.01,
				Description: "Pulse width modulation amount."
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
		// Status: experimental
		name: 'PulseOscExp',
		experimental: true,
		description: "Pulse/square oscillator with pulse width control (w/ linear FM features).",
		inputs: [
			'FM' -> (
				Description: "Control signal for frequency modulation."
			),
			'LinFM' -> (
				Description: "Control signal for linear frequency modulation."
			),
			'PWM' -> (
				Description: "Control signal for pulse width modulation."
			)
		],
		outputs: [
			'Out' -> (
				Description: "Pulse wave oscillator output."
			),
		],
		params: [
			'Range' -> (
				Spec: ControlSpec.new(-2, 2, 'lin', 1, 0),
				LagTime: 0.01,
				Description: "`-2` ... `+2` octaves."
			),
			'Tune' -> (
				Spec: ControlSpec.new(-600, 600, 'lin', 0, 0, "cents"),
				LagTime: 0.01,
				Description: "`-1200` ... `+1200` cents."
			),
			'PulseWidth' -> (
				Spec: \unipolar.asSpec.copy.default_(0.5),
				LagTime: 0.01,
				Description: "Pulse oscillator pulse width."
			),
			'FM' -> (
				Spec: \unipolar.asSpec, // TODO: bipolar?
				LagTime: 0.01,
				Description: "Frequency modulation amount."
			),
			'PWM' -> (
				Spec: \unipolar.asSpec.copy.default_(0.4),
				LagTime: 0.01,
				Description: "Pulse width modulation amount."
			),
			'LinFM' -> (
				Spec: ControlSpec.new(0, 10000, 'lin', nil, 0, "Hz"),
				LagTime: 0.2,
				Description: "Linear frequency modulation amount."
			),
		],
		ugenGraphFunc: {
			|
				in_FM,
				in_LinFM,
				in_PWM,
				out_Out,
				param_Range,
				param_Tune,
				param_FM,
				param_LinFM,
				param_PulseWidth,
				param_PWM
			|

			var sig_FM = In.ar(in_FM);
			var sig_LinFM = In.ar(in_LinFM);
			var sig_PWM = In.ar(in_PWM);

			var fullRange = ControlSpec(12.midicps, 120.midicps);

			var frequency = fullRange.constrain(
				(
					3 +
					param_Range +
					(param_Tune / 1200) +
					(sig_FM * 10 * param_FM) // 0.1 = 1 oct
				).octcps + (sig_LinFM * param_LinFM)
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
		description: "4-in/4-out audio fader with db gain control and mute.",
		inputsDocSection: "\t- `In1` ... `In4`: Audio inputs",
		inputs: {
			4.collect { |index|
				("In"++(index+1)).asSymbol -> (
					Description: "Audio input" + (index+1)
				)
			};
		},
		outputsDocSection: "\t- `Out1` ... `Out4`: Attenuated audio signal outputs",
		outputs: {
			4.collect { |index|
				("Out"++(index+1)).asSymbol -> (
					Description: "Attenuated audio signal output" + (index+1) ++ "."
				)
			};
		},
		params: [
			'Gain' -> (
				Spec: \db.asSpec.copy.maxval_(12).default_(0),
				// TODO LagTime: 0.1
				Description: "Attenuation control. `-inf` ... `+12` dB."
			),
			'Mute' -> (
				Spec: ControlSpec(0, 1, 'lin', 1, 0, ""),
				// TODO LagTime: 0.1
				Description: "If `1` signal is muted, otherwise not."
			),
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
		// status: untested
		// From https://en.wikibooks.org/wiki/Designing_Sound_in_SuperCollider/Schroeder_reverb
		name: 'Rev1',
		experimental: true,
		description: "Schroeder reverb.",
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
		description: "Ring modulator.",
		inputs: [
			'In' -> (
				Description: "Audio signal input."
			),
			'Carrier' -> (
				Description: "Carrier signal input."
			),
		],
		outputs: [
			'Out' -> (
				Description: "Ring modulated audio signal."
			),
		],
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
		// Status: partly tested
		name: 'SampHold',
		description: "Sample and hold module.",
		inputs: [
			'In' -> (
				Description: "Audio signal input."
			),
			'Trig' -> (
				Description: "Trigger signal input."
			),
		],
		outputs: [
			'Out' -> (
				Description: "Processed audio signal."
			),
		],
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
		// Status: tested
		name: 'SawOsc',
		description: "Sawtooth oscillator.",
		inputs: [
			'FM' -> (
				Description: "Control signal for frequency modulation."
			),
		],
		outputs: [
			'Out' -> (
				Description: "Saw wave oscillator output."
			),
		],
		params: [
			'Range' -> (
				Spec: ControlSpec.new(-2, 2, 'lin', 1, 0),
				LagTime: 0.01,
				Description: "`-2` ... `+2` octaves."
			),
			'Tune' -> (
				Spec: ControlSpec.new(-600, 600, 'lin', 0, 0, "cents"),
				LagTime: 0.01,
				Description: "`-1200` ... `+1200` cents."
			),
			'FM' -> (
				Spec: \unipolar.asSpec, // TODO: bipolar?
				LagTime: 0.01,
				Description: "Frequency modulation amount."
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
		// Status: experimental
		name: 'SawOscExp',
		experimental: true,
		description: "Sawtooth oscillator (w/ linear FM features).",
		inputs: [
			'FM' -> (
				Description: "Control signal for frequency modulation."
			),
			'LinFM' -> (
				Description: "Control signal for linear frequency modulation."
			),
		],
		outputs: [
			'Out' -> (
				Description: "Saw wave oscillator output."
			),
		],
		params: [
			'Range' -> (
				Spec: ControlSpec.new(-2, 2, 'lin', 1, 0),
				LagTime: 0.01,
				Description: "`-2` ... `+2` octaves."
			),
			'Tune' -> (
				Spec: ControlSpec.new(-600, 600, 'lin', 0, 0, "cents"),
				LagTime: 0.01,
				Description: "`-1200` ... `+1200` cents."
			),
			'FM' -> (
				Spec: \unipolar.asSpec, // TODO: bipolar?
				LagTime: 0.01,
				Description: "Frequency modulation amount."
			),
			'LinFM' -> (
				Spec: ControlSpec.new(0, 10000, 'lin', nil, 0, "Hz"),
				LagTime: 0.2,
				Description: "Linear frequency modulation amount."
			),
		],
		ugenGraphFunc: {
			|
				in_FM,
				in_LinFM,
				out_Out,
				param_Range,
				param_Tune,
				param_FM,
				param_LinFM
			|

			var sig_FM = In.ar(in_FM);
			var sig_LinFM = In.ar(in_LinFM);

			var fullRange = ControlSpec(12.midicps, 120.midicps);

			var frequency = fullRange.constrain(
				( // TODO: optimization - implement overridable set handlers and do this calculation in sclang rather than server
					3 +
					param_Range +
					(param_Tune / 1200) +
					(sig_FM * 10 * param_FM) // 0.1 = 1 oct
				).octcps + (sig_LinFM * param_LinFM)
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
		experimental: true,
		description: "Control signal sequencer.",
		inputs: [
			'Clock' -> (
				Description: "Clock input."
			),
			'Reset' -> (
				Description: "Reset input."
			),
			'SampleAndHoldCtrl1' -> (
				Description: "Sample and hold control 1."
			),
			'GlideCtrl1' -> (
				Description: "Glide control input 1."
			),
			'SampleAndHoldCtrl2' -> (
				Description: "Sample and hold control 2."
			),
			'GlideCtrl2' -> (
				Description: "Glide control input 2."
			)
		],
		outputs: [
			'Trig1' -> (
				Description: "Trigger output 1."
			),
			'Trig2' -> (
				Description: "Trigger output 2."
			),
			'Gate' -> (
				Description: "Gate output."
			),
			'PreOut1' -> (
				Description: "Pre-output 1."
			),
			'Out1' -> (
				Description: "Output 1."
			),
			'PreOut2' -> (
				Description: "Pre-output 2."
			),
			'Out2' -> (
				Description: "Output 2."
			)
		],
		params: {
			var numSteps = 8;
			var numRows = 2;
			var result = [
					'Reset' -> (
						Spec: \unipolar.asSpec.copy.step_(1), // TODO
						Description: "Manual reset."
					),
					'Step' -> (
						Spec: \unipolar.asSpec.copy.step_(1), // TODO
						Description: "Manual forward step."
					),
					'Range' -> (
						Spec: ControlSpec.new(0, 2, step: 1, default: 0), // 0 = 1V, 1 = 2V, 2 = 4V
						Description: "Output range: `0`, `1` or `2`, specifying ranges `0.1`, `0.2`, `0.4` respectively."
					),
					'Scale' -> (
						Spec: \unipolar.asSpec.copy.default_(1), // TODO
						Description: "TODO"
					),
					'Glide_1' -> (
						Spec: \unipolar.asSpec, // TODO: longer, up to 10 seconds lag as in Softube slew
						Description: "Glide time 1."
					),
					'Glide_2' -> (
						Spec: \unipolar.asSpec, // TODO: longer, up to 10 seconds lag as in Softube slew
						Description: "Glide time 2."
					)
				] ++
				(
					numRows.collect { |rowIndex|
						numSteps.collect { |stepIndex|
							"Trig_"++(rowIndex+1)++"_"++(stepIndex+1) -> (
								Spec: ControlSpec(0, 1, 'lin', 1, 0, ""),
								Description: "Tigger for row"+(rowIndex+1)+"step"+(stepIndex+1)
							)
						} ++
						numSteps.collect { |stepIndex|
							"Value_"++(rowIndex+1)++"_"++(stepIndex+1) -> (
								Spec: \bipolar.asSpec, // TODO: probably make this unipolar to comply with original module
								Description: "Value for row"+(rowIndex+1)+"step"+(stepIndex+1)
							)
						}
					}.flatten ++
					numSteps.collect { |stepIndex|
						"Gate_"++(stepIndex+1) -> (
							Spec: ControlSpec(0, 1, 'lin', 1, 0, ""), // TODO: DRY the gate/reset/boolean specs
							Description: "Gate for step"+(stepIndex+1)
						)
					}
				).collect { |assoc| assoc.key.asSymbol -> assoc.value };
			result; // TODO: remember bug, perform validation that ensures array includes _symbol_ -> definition associations
		},
		visuals: [
			'Position' -> (
				Spec: \unipolar.asSpec,
				Description: "Sequencer position: `0` ... `7`."
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
		description: "2-in/2-out audio fader with db gain control and mute.",
		inputs: [
			'Left' -> (
				Description: "Left channel input."
			),
			'Right' -> (
				Description: "Right channel input."
			)
		],
		outputs: [
			'Left' -> (
				Description: "Attenuated left channel signal."
			),
			'Right' -> (
				Description: "Attenuated right channel signal."
			)
		],
		params: [
			'Gain' -> (
				Spec: \db.asSpec.copy.maxval_(12).default_(0),
				// TODO LagTime: 0.1
				Description: "Attenuation control. `-inf` ... `+12` dB."
			),
			'Mute' -> (
				Spec: ControlSpec(0, 1, 'lin', 1, 0, ""),
				// TODO LagTime: 0.1
				Description: "If `1` signal is muted, otherwise not."
			),
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
		description: "Sine LFO",
		inputs: [
			'Reset' -> (
				Description: "Audio rate reset trigger: when signal is changed from 0 to 1 the LFO is retriggered.",
				Range: [0, 1]
			),
		],
		outputs: [
			'Out' -> (
				Description: "Sine output",
				Range: [-0.25, 0.25]
			),
		],
		params: [
			'Frequency' -> (
				Description: "Frequency `0.01` Hz .. `50` Hz.",
				Spec: ControlSpec(0.01, 50, 'exp', 0, 1, "Hz"),
				LagTime: 0.01
			),
			'Reset' -> (
				Description: "Script reset trigger: when value is changed from `0` to `1` the LFO is retriggered.",
				Spec: \unipolar.asSpec.copy.step_(1), // TODO: generalize booleans (or triggers)
			)
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
		description: "Sine oscillator",
		inputs: [
			'FM' -> (
				Description: "Control signal for frequency modulation."
			),
		],
		outputs: [
			'Out' -> (
				Description: "Sine wave oscillator output."
			),
		],
		params: [
			'Range' -> (
				Spec: ControlSpec.new(-2, 2, 'lin', 1, 0),
				LagTime: 0.01,
				Description: "`-2` ... `+2` octaves."
			),
			'Tune' -> (
				Spec: ControlSpec.new(-600, 600, 'lin', 0, 0, "cents"),
				LagTime: 0.01,
				Description: "`-1200` ... `+1200` cents."
			),
			'FM' -> (
				Spec: \unipolar.asSpec, // TODO: bipolar?
				LagTime: 0.01,
				Description: "Frequency modulation amount."
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
		// Status: tested
		name: 'SineOscExp',
		experimental: true,
		description: "Sine oscillator (w/ linear FM features)",
		inputs: [
			'FM' -> (
				Description: "Control signal for frequency modulation."
			),
			'LinFM' -> (
				Description: "Control signal for linear frequency modulation."
			),
			'PM' -> (
				Description: "Control signal for phase modulation."
			),
		],
		outputs: [
			'Out' -> (
				Description: "Sine wave oscillator output.",
				Range: [-0.5, 0.5]
			),
		],
		params: [
			'Range' -> (
				Spec: ControlSpec.new(-2, 2, 'lin', 1, 0),
				LagTime: 0.01,
				Description: "`-2` ... `+2` octaves."
			),
			'Tune' -> (
				Spec: ControlSpec.new(-600, 600, 'lin', 0, 0, "cents"),
				LagTime: 0.01,
				Description: "`-1200` ... `+1200` cents."
			),
			'FM' -> (
				Spec: \unipolar.asSpec, // TODO: bipolar?
				LagTime: 0.01,
				Description: "Frequency modulation amount."
			),
			'LinFM' -> (
				Spec: ControlSpec.new(0, 10000, 'lin', nil, 0, "Hz"),
				LagTime: 0.2,
				Description: "Linear frequency modulation amount."
			),
			'PM' -> (
				Spec: ControlSpec.new(0, 5, 'lin', 0.01, 0, ""),
				LagTime: 0.2,
				Description: "Phase modulation amount."
			),
		],
		ugenGraphFunc: {
			|
				in_FM,
				in_LinFM,
				in_PM,
				out_Out,
				param_Range,
				param_Tune,
				param_FM,
				param_LinFM,
				param_PM
			|

			var sig_FM = In.ar(in_FM);
			var sig_LinFM = In.ar(in_LinFM);
			var sig_PM = In.ar(in_PM);

			//var fullRange = ControlSpec(12.midicps, 120.midicps); -- removed by andrew (allow higher frequencies for FM synthesis?)

			var frequency =  ( //fullRange.constrain( -- removed by andrew
				( // TODO: optimization - implement overridable set handlers and do this calculation in sclang rather than server
					3 +
					param_Range +
					(param_Tune / 1200) +
					(sig_FM * 10 * param_FM) // 0.1 = 1 oct
				).octcps + (sig_LinFM * param_LinFM)
			);

			Out.ar(
				out_Out,
				SinOsc.ar(frequency, (sig_PM * param_PM * 30).mod(2pi)) * 0.5
			);
		}
	),
	(
		// Status: tested
		name: 'Slew',
		description: "Slew rate limiter.",
		inputs: [
			'In' -> (
				Description: "Audio signal imput."
			),
		],
		outputs: [
			'Out' -> (
				Description: "Processed audio signal."
			),
		],
		params: [
			'Time' -> (
				Spec: ControlSpec.new(0, 60000, units: "ms"),
				LagTime: 0.1,
				Description: "Slew time `0` ... `60 000` ms.",
			),
		],
		ugenGraphFunc: {
			|
				in_In,
				out_Out,
				param_Time
			|

			var sig_In = In.ar(in_In);

			Out.ar(
				out_Out,
				Lag.ar(sig_In, param_Time/1000)
			);
		}
	),
	(
		// Status: untested
		name: 'SPVoice',
		experimental: true,
		inputs: [
			'Gate' -> (
				Description: "Control signal for gate",
			),
			'FM' -> (
				Description: "Control signal for frequency modulation",
			),
		],
		outputs: [
			'Left' -> (
				Description: "Left audio signal",
			),
			'Right' -> (
				Description: "Right audio signal",
			),
		],
		params: [
			'Gate' -> (
				Spec: ControlSpec(0, 1, step: 1, default: 0), // TODO: DRY the gate/reset/boolean specs
				Description: "Manual gate."
			),
			'SampleStart' -> (
				Spec: \unipolar.asSpec,
				Description: "Sample start position normalized to `0` ... `1`."
			),
			'SampleEnd' -> (
				Spec: \unipolar.asSpec.copy.default_(1),
				Description: "Sample end position normalized to `0` ... `1`."
			),
			'LoopPoint' -> (
				Spec: \unipolar.asSpec,
				Description: "Loop point within sample start and end position normalized to `0` ... `1`."
			),
			'LoopEnable' -> (
				Spec: ControlSpec(0, 1, step: 1, default: 0),
				Description: "Loop enabled. `1` means enabled, `0` not."
			),
			'Frequency' -> (
				Spec: \freq.asSpec,
				Description: "Frequency."
			),
			'RootFrequency' -> (
				Spec: \freq.asSpec, // default root is 440 = A4
				Description: "Root frequency."
			),
			'Volume' -> (
				Spec: \db.asSpec.copy.default_(-10),
				Description: "Volume."
			),
			'Pan' -> (
				Spec: \pan.asSpec,
				Description: "Pan position."
			),
			'FM' -> (
				Spec: \unipolar.asSpec, // TODO: bipolar? nah: enfore unipolar on other modules
				LagTime: 0.01,
				Description: "Frequency modulation amount."
			),
		],
		sampleSlots: [
			'Sample' -> (
				Channels: [1, 2],
				Description: "Mono or stereo sample to play."
			) // TODO: include metadata on whether samples are supposed to be enabled for read, write or both, and whether to set a default size for initial sample(s) (to set up a fixed recording buffer, etc)
		],
		visuals: [
			'Phase' -> (
				Spec: \unipolar.asSpec,
				Description: "Sample phase normalized to `0` ... `1`."
			),
			'Gate' -> (
				Spec: ControlSpec(0, 1, step: 1), // TODO: DRY the gate/reset/boolean specs
				Description: "Gate: `0` or `1`."
			),
			'Playing' -> (
				Spec: ControlSpec(0, 1, step: 1), // TODO: DRY the gate/reset/boolean specs
				Description: "Playing: `0` or `1`."
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
		description: "Test sound generator.",
		outputs: [
			'Out' -> (
				Description: "Sine wave signal or noise output."
			)
		],
		params: [
			'Frequency' -> (
				Spec: \widefreq.asSpec,
				LagTime: 0, // TODO: all lag times have to be 0 if params with \db spec (such as param_Amplitude) are used (fixed by resorting to NamedControls in R?)
				Description: "Sine wave frequency."
			),
			'Amplitude' -> (
				Spec: \db.asSpec,
				Description: "Audio output signal amplitude."
			),
			'Wave' -> (
				Spec: ControlSpec(0, 1, step: 1, default: 0),
				Description: "Wave: `0` means sine wave, `1` white noise."
			)
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
		description: "Triangle oscillator (non-bandlimited).",
		inputs: [
			'FM' -> (
				Description: "Control signal for frequency modulation."
			),
		],
		outputs: [
			'Out' -> (
				Description: "Triangle wave oscillator output."
			),
		],
		params: [
			'Range' -> (
				Spec: ControlSpec.new(-2, 2, 'lin', 1, 0),
				LagTime: 0.01,
				Description: "`-2` ... `+2` octaves."
			),
			'Tune' -> (
				Spec: ControlSpec.new(-600, 600, 'lin', 0, 0, "cents"),
				LagTime: 0.01,
				Description: "`-1200` ... `+1200` cents."
			),
			'FM' -> (
				Spec: \unipolar.asSpec, // TODO: bipolar?
				LagTime: 0.01,
				Description: "Frequency modulation amount."
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
		// Status: experimental
		name: 'TriOscExp',
		experimental: true,
		description: "Triangle oscillator (non-bandlimited, w/ linear FM features).",
		inputs: [
			'FM' -> (
				Description: "Control signal for frequency modulation."
			),
			'LinFM' -> (
				Description: "Control signal for linear frequency modulation."
			),
		],
		outputs: [
			'Out' -> (
				Description: "Triangle wave oscillator output."
			),
		],
		params: [
			'Range' -> (
				Spec: ControlSpec.new(-2, 2, 'lin', 1, 0),
				LagTime: 0.01,
				Description: "`-2` ... `+2` octaves."
			),
			'Tune' -> (
				Spec: ControlSpec.new(-600, 600, 'lin', 0, 0, "cents"),
				LagTime: 0.01,
				Description: "`-1200` ... `+1200` cents."
			),
			'FM' -> (
				Spec: \unipolar.asSpec, // TODO: bipolar?
				LagTime: 0.01,
				Description: "Frequency modulation amount."
			),
			'LinFM' -> (
				Spec: ControlSpec.new(0, 10000, 'lin', nil, 0, "Hz"),
				LagTime: 0.2,
				Description: "Linear frequency modulation amount."
			),
		],
		ugenGraphFunc: {
			|
				in_FM,
				in_LinFM,
				out_Out,
				param_Range,
				param_Tune,
				param_FM,
				param_LinFM
			|

			var sig_FM = In.ar(in_FM);
			var sig_LinFM = In.ar(in_LinFM);

			var fullRange = ControlSpec(12.midicps, 120.midicps);

			var frequency = fullRange.constrain(
				( // TODO: optimization - implement overridable set handlers and do this calculation in sclang rather than server
					3 +
					param_Range +
					(param_Tune / 1200) +
					(sig_FM * 10 * param_FM) // 0.1 = 1 oct
				).octcps + (sig_LinFM * param_LinFM)
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
		description: "Crossfader.",
		inputs: [
			'InALeft' -> (
				Description: "Signal A left audio signal."
			),
			'InARight' -> (
				Description: "Signal A right audio signal."
			),
			'InBLeft' -> (
				Description: "Signal B left audio signal."
			),
			'InBRight' -> (
				Description: "Signal B right audio signal."
			),
		],
		outputs: [
			'Left' -> (
				Description: "Crossfaded left audio signal."
			),
			'Right' -> (
				Description: "Crossfaded right audio signal."
			),
		],
		params: [
			'Fade' -> (
				Spec: \bipolar.asSpec, // TODO: remove need for .asSpec
				Description: "Fader position: `-1` fully attenuates stereo signal A, `1` fully attenuates stereo signal B, anything in between mixes the signals."
			),
			'TrimA' -> (
				Spec: \db.asSpec.copy.maxval_(12),
				Description: "Signal A trim."
			),
			'TrimB' -> (
				Spec: \db.asSpec.copy.maxval_(12),
				Description: "Signal B trim."
			),
			'Master' -> (
				Spec: \db.asSpec.copy.maxval_(12),
				Description: "Master output level."
			)
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

var generateMatrixModulesParams = { |numInputs, numOutputs|
	var result = [
		'FadeTime' -> (
			Spec: ControlSpec(0, 1000, 'lin', 0, 5, "ms"),
			Description: "Fade time in milliseconds (range: `0`-`100000` ms) applied when an input is switched on to or off from an output. Default is `5` ms."
		)
	] ++ numInputs.collect { |inIndex|
		numOutputs.collect { |outIndex|
			"Gate_"++(outIndex+1)++"_"++(inIndex+1) -> (
				Spec: ControlSpec(0, 1, 'lin', 1, 0, ""),
				Description: ("Toggle that determine whether input " ++ (inIndex+1) ++ " is switched on to output " ++ (outIndex+1)) ++ "."
			)
		}
	}.flatten.collect { |assoc| assoc.key.asSymbol -> assoc.value };
	result;
};

var generateMatrixModulesInputs = { |numInputs|
	numInputs.collect { |index|
		("In"++(index+1)).asSymbol -> (
			Description: "Input " ++ (index+1)
		)
	};
};

var generateMatrixModulesOutputs = { |numOutputs|
	numOutputs.collect { |index|
		("Out"++(index+1)).asSymbol -> (
			Description: "Output " ++ (index+1)
		)
	};
};

var api = IdentityDictionary[
	\init -> init,
	\free -> free,
	\newCommand -> newCommand,
	\connectCommand -> connectCommand,
	\disconnectCommand -> disconnectCommand,
	\deleteCommand -> deleteCommand,
	\setCommand -> setCommand,
	\bulksetCommand -> bulksetCommand,
	\newmacroCommand -> newmacroCommand,
	\deletemacroCommand -> deletemacroCommand,
	\macrosetCommand -> macrosetCommand,
	\readsampleCommand -> readsampleCommand,
	\tapoutputCommand -> tapoutputCommand,
	\tapclearCommand -> tapclearCommand,
	\getTapBus -> getTapBus,
	\getVisualBus -> getVisualBus,
	\generateDocsForAllModules -> generateDocsForAllModules
];

api
)
