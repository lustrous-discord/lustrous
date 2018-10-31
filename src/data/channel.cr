require "./*"
require "json"

abstract class BaseChannel
  include JSON::Serializable

  getter id   : UInt64
  getter type : Type
  getter name : String? = nil

  enum Type
    GUILD_TEXT, DM, GUILD_VOICE, GROUP_DM, GUILD_CATEGORY
  end
end

abstract class TextChannel < BaseChannel
  include JSON::Serializable

  @[JSON::Field(converter: Time::Format::ISO_8601_DATE_TIME)]
  getter last_pin_timestamp : Time? = nil
  getter last_message_id    : UInt64? = nil
end

class GuildTextChannel < TextChannel
  include JSON::Serializable
  @type = Type::GUILD_TEXT
  
  getter guild_id              : UInt64
  getter position              : Int32
  getter topic                 : String? = nil
  getter nsfw                  : Bool?   = nil
  getter parent_id             : UInt64? = nil
  getter rate_limit_per_user   : Int32?    = nil
  getter permission_overwrites : Array(PermissionOverwrite)? = nil
end

class DMChannel < TextChannel
  include JSON::Serializable
  @type = Type::DM

  getter recipients : Array(Hash(String, JSON::Any))? = nil # TODO: Implement user type
end

class GroupDMChannel < DMChannel
  include JSON::Serializable
  @type = Type::GROUP_DM

  getter icon           : String? = nil
  getter owner_id       : UInt64? = nil
  getter application_id : UInt64? = nil
end

class VoiceChannel < BaseChannel
  include JSON::Serializable
  @type = Type::GUILD_VOICE

  getter guild_id              : UInt64
  getter bitrate               : Int32
  getter position              : Int32
  getter user_limit            : Int32?    = nil
  getter parent_id             : UInt64? = nil
  getter permission_overwrites : Array(PermissionOverwrite)? = nil
end

class ChannelCategory < BaseChannel
  include JSON::Serializable
  @type = Type::GUILD_CATEGORY

  getter guild_id              : UInt64
  getter position              : Int32
  getter parent_id             : UInt64? = nil
  getter permission_overwrites : Array(PermissionOverwrite)? = nil
end

alias GuildChannel = GuildTextChannel | VoiceChannel | ChannelCategory
alias DM = DMChannel | GroupDMChannel