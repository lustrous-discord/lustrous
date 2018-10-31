require "./*"
require "json"

abstract class BaseChannel
  include JSON::Serializable

  getter id   : UInt64
  getter type : ChannelType
  getter name : String? = nil
end

enum ChannelType
  GUILD_TEXT, DM, GUILD_VOICE, GROUP_DM, GUILD_CATEGORY
end

abstract class TextChannel < BaseChannel
  include JSON::Serializable

  getter last_pin_timestamp : Time? = nil
  getter last_message_id    : UInt64? = nil
end

module GuildChannel
  getter guild_id              : UInt64
  getter position              : Int32
  getter parent_id             : UInt64? = nil
  getter permission_overwrites : Array(PermissionOverwrite)? = nil
end

class GuildTextChannel < TextChannel
  include JSON::Serializable
  @type = ChannelType::GUILD_TEXT
  
  include GuildChannel
  getter topic               : String? = nil
  getter nsfw                : Bool?   = nil
  getter rate_limit_per_user : Int32?  = nil
end

class DMChannel < TextChannel
  include JSON::Serializable
  @type = ChannelType::DM

  getter recipients : Array(Hash(String, JSON::Any))? = nil # TODO: Implement user type
end

class GroupDMChannel < DMChannel
  include JSON::Serializable
  @type = ChannelType::GROUP_DM

  getter icon           : String? = nil
  getter owner_id       : UInt64? = nil
  getter application_id : UInt64? = nil
end

class VoiceChannel < BaseChannel
  include JSON::Serializable
  @type = ChannelType::GUILD_VOICE

  include GuildChannel
  getter bitrate               : Int32
  getter user_limit            : Int32? = nil
end

class ChannelCategory < BaseChannel
  include JSON::Serializable
  @type = ChannelType::GUILD_CATEGORY

  include GuildChannel
end