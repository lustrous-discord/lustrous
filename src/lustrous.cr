require "./network/*"

# TODO: Finish gateway implementation (see network/gateway.cr)
# TODO: Finish API implementation (see network/api.cr)
# TODO: Add caching implementation
# TODO: Create bot framework

module Lustrous
  URL = "https://github.com/lustrous-discord/lustrous"
  VER = "0.1.0"
end

class Lustrous::Bot
  def initialize(@token : String)
    @api = API.new @token
    @gateway = Gateway.new @token, @api
    @gateway.connect
  end
end