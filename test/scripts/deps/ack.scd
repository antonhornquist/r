(
var include_relative = { |relative_path|
	var path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ relative_path).standardizePath;
	if (File.exists(path)) {
		this.executeFile(path);
	} {
		Error("include_relative: file % does not exist".format(path.quote)).throw;
	};
};

var numChannels = 8;

var ack = include_relative.value("../../ack.scd");
var getChannelSpecs = ack[\getChannelSpecs];
var getEffectSpecs = ack[\getEffectSpecs];

var channelSpecs = getChannelSpecs.value;
var effectSpecs = getEffectSpecs.value;

var formatters = include_relative.value("formatters.scd");

var add_channel_sample_param = { |channel|
	~params.add_(
		(
			type: "file",
			id: channel.asString++"_sample",
			name: channel.asString++": sample",
			action: { |value|
				if (value != "-") {
					~engine.loadSample_(channel-1, value)
				};
			}
		)
	);
};

var add_start_pos_param = { |channel|
	~params.add_(
		(
			type: "control",
			id: channel.asString++"_start_pos",
			name: channel.asString++": start pos",
			controlspec: channelSpecs[\sampleStart],
			formatter: formatters[\unipolar_as_percentage],
			action: { |value| ~engine.sampleStart_(channel-1, value) }
		)
	);
};

var add_end_pos_param = { |channel|
	~params.add_(
		(
			type: "control",
			id: channel.asString++"_end_pos",
			name: channel.asString++": end pos",
			controlspec: channelSpecs[\sampleEnd],
			formatter: formatters[\unipolar_as_percentage],
			action: { |value| ~engine.sampleEnd_(channel-1, value) }
		)
	);
};

var add_loop_param = { |channel|
	~params.add_(
		(
			type: "option",
			id: channel.asString++"_loop",
			name: channel.asString++": loop",
			options: ["off", "on"],
			action: { |value|
				if (value == 2) {
					~engine.enableLoop_(channel-1)
				} {
					~engine.disableLoop_(channel-1)
				}
			}
		)
	);
};

var add_loop_point_param = { |channel|
	~params.add_(
		(
			type: "control",
			id: channel.asString++"_loop_point",
			name: channel.asString++": loop point",
			controlspec: channelSpecs[\loopPoint],
			formatter: formatters[\unipolar_as_percentage],
			action: { |value| ~engine.loopPoint_(channel-1, value) }
		)
	);
};

var add_speed_param = { |channel|
	~params.add_(
		(
			type: "control",
			id: channel.asString++"_speed",
			name: channel.asString++": speed",
			controlspec: channelSpecs[\speed],
			formatter: formatters[\unipolar_as_percentage],
			action: { |value| ~engine.speed_(channel-1, value) }
		)
	);
};

var add_vol_param = { |channel|
	~params.add_(
		(
			type: "control",
			id: channel.asString++"_vol",
			name: channel.asString++": vol",
			controlspec: channelSpecs[\vol],
			formatter: formatters[\default],
			action: { |value| ~engine.volume_(channel-1, value) }
		)
	);
};

var add_vol_env_atk_param = { |channel|
	~params.add_(
		(
			type: "control",
			id: channel.asString++"_vol_env_atk",
			name: channel.asString++": vol env atk",
			controlspec: channelSpecs[\volumeEnvAttack],
			formatter: formatters[\secs_as_ms],
			action: { |value| ~engine.volumeEnvAttack_(channel-1, value) }
		)
	);
};

var add_vol_env_rel_param = { |channel|
	~params.add_(
		(
			type: "control",
			id: channel.asString++"_vol_env_rel",
			name: channel.asString++": vol env rel",
			controlspec: channelSpecs[\volumeEnvRelease],
			formatter: formatters[\secs_as_ms],
			action: { |value| ~engine.volumeEnvRelease_(channel-1, value) }
		)
	);
};

var add_pan_param = { |channel|
	~params.add_(
		(
			type: "control",
			id: channel.asString++"_pan",
			name: channel.asString++": pan",
			controlspec: channelSpecs[\pan],
			formatter: formatters[\bipolar_as_pan_widget],
			action: { |value| ~engine.pan_(channel-1, value) }
		)
	);
};

var add_filter_cutoff_param = { |channel|
	~params.add_(
		(
			type: "control",
			id: channel.asString++"_filter_cutoff",
			name: channel.asString++": filter cutoff",
			controlspec: channelSpecs[\filterCutoff],
			formatter: formatters[\round].value(0.001),
			action: { |value| ~engine.filterCutoff_(channel-1, value) }
		)
	);
};

var add_filter_res_param = { |channel|
	~params.add_(
		(
			type: "control",
			id: channel.asString++"_filter_res",
			name: channel.asString++": filter res",
			controlspec: channelSpecs[\filterRes],
			formatter: formatters[\unipolar_as_percentage],
			action: { |value| ~engine.filterRes_(channel-1, value) }
		)
	);
};

var add_filter_mode_param = { |channel|
	~params.add_(
		(
			type: "option",
			id: channel.asString++"_filter_mode",
			name: channel.asString++": filter mode",
			options: ["lowpass", "bandpass", "highpass", "notch", "peak"],
			action: { |value| ~engine.filterMode_(channel-1, value-1) }
		)
	);
};

var add_filter_env_atk_param = { |channel|
	~params.add_(
		(
			type: "control",
			id: channel.asString++"_filter_env_atk",
			name: channel.asString++": filter env atk",
			controlspec: channelSpecs[\filterEnvAttack],
			formatter: formatters[\secs_as_ms],
			action: { |value| ~engine.filterEnvAttack_(channel-1, value) }
		)
	);
};

var add_filter_env_rel_param = { |channel|
	~params.add_(
		(
			type: "control",
			id: channel.asString++"_filter_env_rel",
			name: channel.asString++": filter env rel",
			controlspec: channelSpecs[\filterEnvRelease],
			formatter: formatters[\secs_as_ms],
			action: { |value| ~engine.filterEnvRelease_(channel-1, value) }
		)
	);
};

var add_filter_env_mod_param = { |channel|
	~params.add_(
		(
			type: "control",
			id: channel.asString++"_filter_env_mod",
			name: channel.asString++": filter env mod",
			controlspec: channelSpecs[\filterEnvMod],
			formatter: formatters[\bipolar_as_percentage],
			action: { |value| ~engine.filterEnvMod_(channel-1, value) }
		)
	);
};

var add_sample_rate_param = { |channel|
	~params.add_(
		(
			type: "control",
			id: channel.asString++"_sample_rate",
			name: channel.asString++": sample rate",
			controlspec: channelSpecs[\sampleRate],
			formatter: formatters[\default],
			action: { |value| ~engine.sampleRate_(channel-1, value) }
		)
	);
};

var add_bit_depth_param = { |channel|
	~params.add_(
		(
			type: "control",
			id: channel.asString++"_bit_depth",
			name: channel.asString++": bit depth",
			controlspec: channelSpecs[\bitDepth],
			formatter: formatters[\default],
			action: { |value| ~engine.bitDepth_(channel-1, value) }
		)
	);
};

var add_dist_param = { |channel|
	~params.add_(
		(
			type: "control",
			id: channel.asString++"_dist",
			name: channel.asString++": dist",
			controlspec: channelSpecs[\dist],
			formatter: formatters[\unipolar_as_percentage],
			action: { |value| ~engine.dist_(channel-1, value) }
		)
	);
};

var add_mutegroup_param = { |channel|
	~params.add_(
		(
			type: "option",
			id: channel.asString++"_in_mutegroup",
			name: channel.asString++": in mutegroup",
			options: ["no", "yes"],
			action: { |value|
				if (value == 2) {
					~engine.includeInMuteGroup_(channel-1, 1)
				} {
					~engine.includeInMuteGroup_(channel-1, 0)
				};
			}
		)
	);
};

var add_delay_send_param = { |channel|
	~params.add_(
		(
			type: "control",
			id: channel.asString++"_delay_send",
			name: channel.asString++": delay send",
			controlspec: channelSpecs[\delaySend],
			formatter: formatters[\default],
			action: { |value| ~engine.delaySend_(channel-1, value) }
		)
	);
};

var add_reverb_send_param = { |channel|
	~params.add_(
		(
			type: "control",
			id: channel.asString++"_reverb_send",
			name: channel.asString++": reverb send",
			controlspec: channelSpecs[\reverbSend],
			formatter: formatters[\default],
			action: { |value| ~engine.reverbSend_(channel-1, value) }
		)
	);
};

var add_channel_params = { |channel|
	add_channel_sample_param.value(channel);
	add_start_pos_param.value(channel);
	add_end_pos_param.value(channel);
	add_loop_param.value(channel);
	add_loop_point_param.value(channel);
	add_speed_param.value(channel);
	add_vol_param.value(channel);
	add_vol_env_atk_param.value(channel);
	add_vol_env_rel_param.value(channel);
	add_pan_param.value(channel);
	add_filter_mode_param.value(channel);
	add_filter_cutoff_param.value(channel);
	add_filter_res_param.value(channel);
	add_filter_env_atk_param.value(channel);
	add_filter_env_rel_param.value(channel);
	add_filter_env_mod_param.value(channel);
	add_sample_rate_param.value(channel);
	add_bit_depth_param.value(channel);
	add_dist_param.value(channel);
	add_mutegroup_param.value(channel);
	add_delay_send_param.value(channel);
	add_reverb_send_param.value(channel);
};

var add_delay_time_param = {
	~params.add_(
		(
			type: "control",
			id: "delay_time",
			name: "delay time",
			controlspec: effectSpecs[\delayTime],
			formatter: formatters[\secs_as_ms],
			action: { |value| ~engine.delayTime_(value) }
		)
	);
};

var add_delay_feedback_param = {
	~params.add_(
		(
			type: "control",
			id: "delay_feedback",
			name: "delay feedback",
			controlspec: effectSpecs[\delayFeedback],
			formatter: formatters[\unipolar_as_percentage],
			action: { |value| ~engine.delayFeedback_(value) }
		)
	);
};

var add_delay_level_param = {
	~params.add_(
		(
			type: "control",
			id: "delay_level",
			name: "delay level",
			controlspec: effectSpecs[\delayLevel],
			formatter: formatters[\default],
			action: { |value| ~engine.delayLevel_(value) }
		)
	);
};

var add_reverb_room_size_param = {
	~params.add_(
		(
			type: "control",
			id: "reverb_room_size",
			name: "reverb room size",
			controlspec: effectSpecs[\reverbRoom],
			formatter: formatters[\unipolar_as_percentage],
			action: { |value| ~engine.reverbRoom_(value) }
		)
	);
};

var add_reverb_damp_param = {
	~params.add_(
		(
			type: "control",
			id: "reverb_damp",
			name: "reverb damp",
			controlspec: effectSpecs[\reverbDamp],
			formatter: formatters[\unipolar_as_percentage],
			action: { |value| ~engine.reverbDamp_(value) }
		)
	);
};

var add_reverb_level_param = {
	~params.add_(
		(
			type: "control",
			id: "reverb_level",
			name: "reverb level",
			controlspec: effectSpecs[\reverbLevel],
			formatter: formatters[\default],
			action: { |value| ~engine.reverbLevel_(value) }
		)
	);
};

var add_effects_params = {
	add_delay_time_param.value();
	add_delay_feedback_param.value();
	add_delay_level_param.value();
	add_reverb_room_size_param.value();
	add_reverb_damp_param.value();
	add_reverb_level_param.value();
};

var add_params = {
	numChannels.do { |channelnum|
		add_channel_params.value(channelnum+1);
		// TODO ~params.add_separator_();
	};

	add_effects_params.value();
};

var exports = IdentityDictionary[
	\add_params -> add_params,
	\add_channel_params -> add_channel_params,
	\add_effects_params -> add_effects_params,
	\add_channel_sample_param -> add_channel_sample_param,
	\add_start_pos_param -> add_start_pos_param,
	\add_end_pos_param -> add_end_pos_param,
	\add_loop_param -> add_loop_param,
	\add_loop_point_param -> add_loop_point_param,
	\add_speed_param -> add_speed_param,
	\add_vol_param -> add_vol_param,
	\add_vol_env_atk_param -> add_vol_env_atk_param,
	\add_vol_env_rel_param -> add_vol_env_rel_param,
	\add_pan_param -> add_pan_param,
	\add_filter_cutoff_param -> add_filter_cutoff_param,
	\add_filter_res_param -> add_filter_res_param,
	\add_filter_mode_param -> add_filter_mode_param,
	\add_filter_env_atk_param -> add_filter_env_atk_param,
	\add_filter_env_rel_param -> add_filter_env_rel_param,
	\add_filter_env_mod_param -> add_filter_env_mod_param,
	\add_sample_rate_param -> add_sample_rate_param,
	\add_bit_depth_param -> add_bit_depth_param,
	\add_dist_param -> add_dist_param,
	\add_mutegroup_param -> add_mutegroup_param,
	\add_delay_send_param -> add_delay_send_param,
	\add_reverb_send_param -> add_reverb_send_param,
	\add_delay_time_param -> add_delay_time_param,
	\add_delay_feedback_param -> add_delay_feedback_param,
	\add_delay_level_param -> add_delay_level_param,
	\add_reverb_room_size_param -> add_reverb_room_size_param,
	\add_reverb_damp_param -> add_reverb_damp_param,
	\add_reverb_level_param -> add_reverb_level_param
];

exports
)
