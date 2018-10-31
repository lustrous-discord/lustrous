require "json"

@[Flags]
enum Permissions
  CREATE_INSTANT_INVITE
  KICK_MEMBERS
  BAN_MEMBERS
  ADMINISTRATOR
  MANAGE_CHANNELS
  MANAGE_GUILD
  ADD_REACTIONS
  VIEW_AUDIT_LOG
  VIEW_CHANNEL
  SEND_MESSAGES
  SEND_TTS_MESSAGES
  MANAGE_MESSAGES
  EMBED_LINKS
  ATTACH_FILES
  READ_MESSAGE_HISTORY
  MENTION_EVERYONE
  USE_EXTERNAL_EMOJIS
  CONNECT
  SPEAK
  MUTE_MEMBERS
  DEAFEN_MEMBERS
  MOVE_MEMBERS
  USE_VAD
  PRIORITY_SPEAKER
  CHANGE_NICKNAME
  MANAGE_NICKNAMES
  MANAGE_ROLES
  MANAGE_WEBHOOKS
  MANAGE_EMOJIS
end

class PermissionOverwrite
  include JSON::Serializable

  getter id    : UInt64
  getter type  : String
  getter allow : Int32
  getter deny  : Int32
end

class Role
  include JSON::Serializable

  getter id          : UInt64
  getter name        : String
  getter color       : Int32
  getter hoist       : Bool
  getter position    : Int32
  getter permissions : Int32
  getter managed     : Bool
  getter mentionable : Bool
end