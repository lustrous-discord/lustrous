require "../lustrous"
require "crest"
require "json"

# TODO: Implement remaining API methods
# TODO: Implement rate limit protection
# TODO: Implement caching

class Lustrous::API
  def initialize(@token : String)
    @discord = Crest::Resource.new("https://discordapp.com/api/v6") do |resource|
      resource.headers.merge!({
        "Authorization" => "Bot "+@token,
        "User-Agent"    => "DiscordBot (#{Lustrous::URL}, #{Lustrous::VER})"
      })
    end
  end

  enum HttpMethod; GET, PUT, POST, PATCH, DELETE end
  private def request(method : HttpMethod, path : String, args = {} of String => JSON::Any)
    path, args = fmtpath(path, args)
    response = case method
    when .put?     then @discord[path].put     form: args.to_json
    when .post?    then @discord[path].post    form: args.to_json
    when .patch?   then @discord[path].patch   form: args.to_json
    when .get?     then @discord[path].get     params: args.transform_values &.to_s
    when .delete?  then @discord[path].delete  params: args.transform_values &.to_s
    else raise "Invalid method #{method} passed to Lustrous::API#request - this is a bug!"
    end

    return nil if response.status_code/100 != 2
    JSON.parse(response.body)
  end

  private def fmtpath(path : String, args = {} of String => JSON::Any, limit = 0)
    newp, loopc = path, 0
    args.select {|k,v| path.includes? "%#{k}%"}.each do |key, value|
      newp = newp.gsub("%#{key}%", value.to_s)
      break if limit && (loopc += 1) >= limit
    end

    {newp, args.reject {|k,v| path.includes? "%#{k}%"}}
  end

  private macro endpoint(name, method, path, *args)
    def {{name.id}}({{*args}})
      request(HttpMethod::{{method.id}}, {{path}},
        {% if !args.empty? %} { {% for arg in args %} "{{arg.var}}" => {{arg.var}}, {% end %} } {% end %})
    end
  end

  # TODO: Finish up API method details
  # - Implement file uploads
  # - Implement role types
  # - Implement embed types
  # - Implement channel types
  # - Abstract out perm override types
  # - Fix parameter case for create_guild_ban
  # - Fix content splatting for modify_guild_role_positions
  # - Fix content splatting for modify_guild_channel_positions

  endpoint get_gateway, GET, "/gateway"
  endpoint get_gateway_bot, GET, "/gateway/bot"

  endpoint get_guild_audit_log, GET, "/guilds/%gid%/audit-logs",
    gid         : UInt64,
    user_id     : UInt64,
    action_type : Int,
    before      : UInt64,
    limit       : Int

  endpoint get_channel, GET, "/channels/%cid%",
    cid : UInt64
  endpoint modify_channel, PATCH, "/channels/%cid%",
    cid                   : UInt64,
    name                  : String? = nil,
    position              : Int? = nil,
    topic                 : String? = nil,
    nsfw                  : Bool? = nil,
    rate_limit_per_user   : Int? = nil,
    bitrate               : Int? = nil,
    user_limit            : Int? = nil,
    permission_overwrites : Array({ id: UInt64, type: String, allow: Int, deny: Int })? = nil,
    parent_id             : UInt64? = nil
  endpoint delete_channel, DELETE, "/channels/%cid%",
    cid : UInt64
  endpoint get_channel_messages, GET, "/channels/%cid%/messages",
    cid    : UInt64,
    around : UInt64? = nil,
    before : UInt64? = nil,
    after  : UInt64? = nil,
    limit  : Int? = nil
  endpoint get_channel_message, GET, "/channels/%cid%/messages/%mid%",
    cid : UInt64,
    mid : UInt64
  endpoint create_message, POST, "/channels/%cid%/messages",
    cid     : UInt64,
    content : String,
    nonce   : UInt64? = nil,
    tts     : Bool? = nil,
    file    : Nil = nil,                     # TODO: Implement file uploads
    embed   : Hash(String, JSON::Any)? = nil # TODO: Implement embed types
  endpoint create_reaction, PUT, "/channels/%cid%/messages/%mid%/reactions/%emoji%/@me",
    cid   : UInt64,
    mid   : UInt64,
    emoji : String | UInt64
  endpoint delete_own_reaction, DELETE, "/channels/%cid%/messages/%mid%/reactions/%emoji%/@me",
    cid   : UInt64,
    mid   : UInt64,
    emoji : String | UInt64
  endpoint delete_user_reaction, DELETE, "/channels/%cid%/messages/%mid%/reactions/%emoji%/%uid%",
    cid   : UInt64,
    mid   : UInt64,
    emoji : String | UInt64,
    uid   : UInt64
  endpoint get_reactions, GET, "/channels/%cid%/messages/%mid%/reactions/%emoji%",
    cid   : UInt64,
    mid   : UInt64,
    emoji : String | UInt64
  endpoint delete_all_reactions, DELETE, "/channels/%cid%/messages/%mid%/reactions",
    cid : UInt64,
    mid : UInt64
  endpoint edit_message, PATCH, "/channels/%cid%/messages/%mid%",
    cid     : UInt64,
    mid     : UInt64,
    content : String? = nil,
    embed   : Hash(String, JSON::Any)? = nil # TODO: Implement embed types
  endpoint delete_message, DELETE, "/channels/%cid%/messages/%mid%",
    cid : UInt64,
    mid : UInt64
  endpoint bulk_delete_messages, POST, "/channels/%cid%/messages/bulk-delete",
    cid      : UInt64,
    messages : Array(UInt64)
  endpoint edit_channel_permissions, PUT, "/channels/%cid%/permissions/%oid%",
    cid   : UInt64,
    oid   : UInt64,
    allow : Int,
    deny  : Int,
    type  : String
  endpoint get_channel_invites, GET, "/channels/%cid%/invites",
    cid : UInt64
  endpoint create_channel_invite, POST, "/channels/%cid%/invites",
    cid       : UInt64,
    max_age   : Int? = nil,
    max_uses  : Int? = nil,
    temporary : Bool? = nil,
    unique    : Bool? = nil
  endpoint delete_channel_permission, DELETE, "/channels/%cid%/permissions/%oid%",
    cid : UInt64,
    oid : UInt64
  endpoint trigger_typing_indicator, POST, "/channels/%cid%/typing",
    cid : UInt64
  endpoint get_pinned_messages, GET, "/channels/%cid%/pins",
    cid : UInt64
  endpoint add_pinned_channel_message, PUT, "/channels/%cid%/pins/%mid%",
    cid : UInt64,
    mid : UInt64
  endpoint delete_pinned_channel_message, DELETE, "/channels/%cid%/pins/%mid%",
    cid : UInt64,
    mid : UInt64
  endpoint group_dm_add_recipient, PUT, "/channels/%cid%/recipients/%uid%",
    cid          : UInt64,
    uid          : UInt64,
    access_token : String,
    nick         : String? = nil
  endpoint group_dm_remove_recipient, DELETE, "/channels/%cid%/recipients/%uid%",
    cid : UInt64,
    uid : UInt64

  endpoint list_guild_emojis, GET, "/guilds/%gid%/emojis",
    gid : UInt64
  endpoint get_guild_emoji, GET, "/guilds/%gid%/emojis/%eid%",
    gid : UInt64,
    eid : UInt64
  endpoint create_guild_emoji, POST, "/guilds/%gid%/emojis",
    gid   : UInt64,
    name  : String,
    image : String,
    roles : Array(UInt64)? = nil
  endpoint modify_guild_emoji, PATCH, "/guilds/%gid%/emojis/%eid%",
    gid   : UInt64,
    eid   : UInt64,
    name  : String? = nil,
    roles : Array(UInt64)? = nil
  endpoint delete_guild_emoji, DELETE, "/guilds/%gid%/emojis/%eid%",
    gid : UInt64,
    eid : UInt64

  endpoint create_guild, POST, "/guilds",
    gid                           : UInt64,
    name                          : String,
    region                        : String,
    icon                          : String,
    verification_level            : Int,
    default_message_notifications : Int,
    explicit_content_filter       : Int,
    roles                         : Array(Hash(String, JSON::Any)), # TODO: Implement role types
    channels                      : Array(Hash(String, JSON::Any))  # TODO: Implement channel types
  endpoint get_guild, GET, "/guilds/%gid%",
    gid : UInt64
  endpoint modify_guild, PATCH, "/guilds/%gid%",
    gid                           : UInt64,
    name                          : String? = nil,
    region                        : String? = nil,
    verification_level            : Int? = nil,
    default_message_notifications : Int? = nil,
    explicit_content_filter       : Int? = nil,
    afk_channel_id                : UInt64? = nil,
    afk_timeout                   : Int? = nil,
    icon                          : String? = nil,
    owner_id                      : UInt64? = nil,
    splash                        : String? = nil,
    system_channel_id             : UInt64? = nil
  endpoint delete_guild, DELETE, "/guilds/%gid%",
    gid : UInt64
  endpoint get_guild_channels, GET, "/guilds/%gid%/channels",
    gid : UInt64
  endpoint create_guild_channel, POST, "/guilds/%gid%/channels",
    gid                   : UInt64,
    name                  : String,
    type                  : Int? = nil,
    topic                 : String? = nil,
    bitrate               : Int? = nil,
    user_limit            : Int? = nil,
    rate_limit_per_user   : Int? = nil,
    permission_overwrites : Array({ id: UInt64, type: String, allow: Int, deny: Int })? = nil,
    parent_id             : UInt64? = nil,
    nsfw                  : Bool? = nil
  endpoint modify_guild_channel_positions, PATCH, "/guilds/%gid%/channels",
    gid      : UInt64,
    channels : Array({id: UInt64, position: Int}) # TODO: Implement, this needs to be splatted as the full content
  endpoint get_guild_member, GET, "/guilds/%gid%/members/%uid%",
    gid : UInt64,
    uid : UInt64
  endpoint list_guild_members, GET, "/guilds/%gid%/members",
    gid   : UInt64,
    limit : Int? = nil,
    after : UInt64? = nil
  endpoint add_guild_member, PUT, "/guilds/%gid%/members/%uid%",
    gid : UInt64,
    uid : UInt64,
    access_token : String,
    nick  : String? = nil,
    roles : Array(UInt64)? = nil,
    mute  : Bool? = nil,
    deaf  : Bool? = nil
  endpoint modify_guild_member, PATCH, "/guilds/%gid%/members/%uid%",
    gid        : UInt64,
    uid        : UInt64,
    nick       : String? = nil,
    roles      : Array(UInt64)? = nil,
    mute       : Bool? = nil,
    deaf       : Bool? = nil,
    channel_id : UInt64? = nil
  endpoint modify_current_user_nick, PATCH, "/guilds/%gid%/members/@me/nick",
    gid  : UInt64,
    nick : String
  endpoint add_guild_member_role, PUT, "/guilds/%gid%/members/%uid%/roles/%rid%",
    gid : UInt64,
    uid : UInt64,
    rid : UInt64
  endpoint remove_guild_member_role, DELETE, "/guilds/%gid%/members/%uid%/roles/%rid%",
    gid : UInt64,
    uid : UInt64,
    rid : UInt64
  endpoint remove_guild_member, DELETE, "/guilds/%gid%/members/%uid%",
    gid : UInt64,
    uid : UInt64
  endpoint get_guild_bans, GET, "/guilds/%gid%/bans",
    gid : UInt64
  endpoint get_guild_ban, GET, "/guilds/%gid%/bans/%uid%",
    gid : UInt64,
    uid : UInt64
  endpoint create_guild_ban, PUT, "/guilds/%gid%/bans/%uid%",
    gid                 : UInt64,
    uid                 : UInt64,
    delete_message_days : Int? = nil, # TODO: Fix this - should be skewer case (I really hate this endpoint)
    reason              : String? = nil
  endpoint remove_guild_ban, DELETE, "/guilds/%gid%/bans/%uid%",
    gid : UInt64,
    uid : UInt64
  endpoint get_guild_roles, GET, "/guilds/%gid%/roles",
    gid : UInt64
  endpoint create_guild_role, POST, "/guilds/%gid%/roles",
    gid         : UInt64,
    name        : String? = nil,
    permissions : Int? = nil,
    color       : Int? = nil,
    hoist       : Bool? = nil,
    mentionable : Bool? = nil
  endpoint modify_guild_role_positions, PATCH, "/guilds/%gid%/roles",
    gid   : UInt64,
    roles : Array({id: UInt64, position: Int}) # TODO: Implement, this needs to be splatted as the full content
  endpoint modify_guild_role, PATCH, "/guilds/%gid%/roles/%rid%",
    gid         : UInt64,
    rid         : UInt64,
    name        : String? = nil,
    permissions : Int? = nil,
    color       : Int? = nil,
    hoist       : Bool? = nil,
    mentionable : Bool? = nil
  endpoint delete_guild_role, DELETE, "/guilds/%gid%/roles/%rid%",
    gid : UInt64,
    rid : UInt64
  endpoint get_guild_prune_count, GET, "/guilds/%gid%/prune",
    gid  : UInt64,
    days : Int
  endpoint begin_guild_prune, POST, "/guilds/%gid%/prune",
    gid  : UInt64,
    days : Int
  endpoint get_guild_voice_regions, GET, "/guilds/%gid%/regions",
    gid : UInt64
  endpoint get_guild_invites, GET, "/guilds/%gid%/invites",
    gid : UInt64
  endpoint get_guild_integrations, GET, "/guilds/%gid%/integrations",
    gid : UInt64
  endpoint create_guild_integration, POST, "/guilds/%gid%/integrations",
    gid  : UInt64,
    type : String,
    id   : UInt64
  endpoint modify_guild_integration, PATCH, "/guilds/%gid%/integrations/%iid%",
    gid                 : UInt64,
    iid                 : UInt64,
    expire_behavior     : Int? = nil,
    expire_grace_period : Int? = nil,
    enable_emoticons    : Bool? = nil
  endpoint delete_guild_integration, DELETE, "/guilds/%gid%/integrations/%iid%",
    gid : UInt64,
    iid : UInt64
  endpoint sync_guild_integration, POST, "/guilds/%gid%/integrations/%iid%/sync",
    gid : UInt64,
    iid : UInt64
  endpoint get_guild_embed, GET, "/guilds/%gid%/embed",
    gid : UInt64
  endpoint modify_guild_embed, PATCH, "/guilds/%gid%/embed",
    gid : UInt64
  endpoint get_guild_vanity_url, GET, "/guilds/%gid%/vanity-url",
    gid : UInt64

  endpoint get_invite, GET, "/invites/%icode%",
    icode       : String,
    with_counts : Bool? = nil
  endpoint delete_invite, DELETE, "/invites/%icode%",
    icode : String

  endpoint get_current_user, GET, "/users/@me"
  endpoint get_user, GET, "/users/%uid%",
    uid : UInt64
  endpoint modify_current_user, PATCH, "/users/@me",
    username : String? = nil,
    avatar   : String? = nil
  endpoint get_current_user_guilds, GET, "/users/@me/guilds",
    before : UInt64? = nil,
    after  : UInt64? = nil,
    limit  : Int? = nil
  endpoint leave_guild, DELETE, "/users/@me/guilds/%gid%",
    gid : UInt64
  endpoint get_user_dms, GET, "/users/@me/channels"
  endpoint create_dm, POST, "/users/@me/channels",
    recipient_id : UInt64
  endpoint create_group_dm, POST, "/users/@me/channels",
    access_tokens : Array(String),
    nicks         : Hash(UInt64, String)? = nil
  endpoint get_user_connections, GET, "/users/@me/connections"

  endpoint list_voice_regions, GET, "/voice/regions"

  endpoint create_webhook, POST, "/channels/%cid%/webhooks",
    cid : UInt64
  endpoint get_channel_webhooks, GET, "/channels/%cid%/webhooks",
    cid : UInt64
  endpoint get_guild_webhooks, GET, "/guilds/%gid%/webhooks",
    gid : UInt64
  endpoint get_webhook, GET, "/webhooks/%wid%",
    wid : UInt64
  endpoint get_webhook_with_token, GET, "/webhooks/%wid%/%wtoken%",
    wid : UInt64,
    wtoken : String
  endpoint modify_webhook, PATCH, "/webhooks/%wid%",
    wid        : UInt64,
    name       : String? = nil,
    avatar     : String? = nil,
    channel_id : UInt64? = nil
  endpoint modify_webhook_with_token, PATCH, "/webhooks/%wid%/%wtoken%",
    wid : UInt64,
    wtoken : String
  endpoint delete_webhook, DELETE, "/webhooks/%wid%",
    wid : UInt64
  endpoint delete_webhook_with_token, DELETE, "/webhooks/%wid%/%wtoken%",
    wid : UInt64,
    wtoken : String
  endpoint execute_webhook, POST, "/webhooks/%wid%/%wtoken%",
    wid        : UInt64,
    wtoken     : String,
    content    : String,
    username   : String? = nil,
    avatar_url : String? = nil,
    tts        : Boolean? = nil,
    file       : Nil = nil,                            # TODO: Implement file uploads
    embeds     : Array(Hash(String, JSON::Any))? = nil # TODO: Implement embed types
  # endpoint execute_slack_compatible_webhook, POST, "/webhooks/%wid%/%wtoken%/slack",
  #   wid : UInt64,
  #   wtoken : String
  # endpoint execute_github_compatible_webhook, POST, "/webhooks/%wid%/%wtoken%/github",
  #   wid : UInt64,
  #   wtoken : String
end