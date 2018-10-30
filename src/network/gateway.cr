require "./api"
require "http"
require "json"

# TODO: Add event dispatch
# TODO: Add outgoing gateway message methods
# TODO: Make sure reconnecting logic works right
# TODO: Implement caching

class Lustrous::Gateway
  @gwu : String
  @ws  : HTTP::WebSocket | Nil
  @api : API
  @seq = 0_i64
  @sid : String | Nil
  @hbi = 0
  @ack = true

  def initialize(@token : String, api : API | Nil = nil)
    @api = api || API.new(@token)
    @gwu = @api.get_gateway.try &.["url"]?.try &.as_s || raise "Could not get gateway url"
  end

  def connect : Nil;
    @ws = ws = HTTP::WebSocket.new("#{@gwu}/?v=6&encoding=json")

    ws.on_message do |message|
      message = GatewayMessage.from_json(message)
      @seq = message.s || @seq

      case message.op
      when .hello?
        @hbi = message.d["heartbeat_interval"].as_i

        spawn do loop do
          sleep @hbi/1000_f32
          break reconnect unless @ack
          @ack = false
          send_heartbeat
        end end

        send_resume if @sid && @seq
        send_identify if !@sid || !@seq

      when .heartbeat_ack? then @ack = true
      when .reconnect? then reconnect
      when .invalid_session? then reconnect false
      
      when .dispatch?
        @sid = message.d["session_id"].as_s if message.t == "READY"
        puts message.t
      end
    end

    ws.on_close do |reason|
      puts "Closed: "+reason
    end

    ws.run
  end

  def reconnect(resume = true) : Nil
    disconnect resume
    connect
  end

  def disconnect(resume = false) : Nil
    @ws.try &.close
    @ack = true
    @hbi = 0
    if !resume
      @seq = 0
      @sid = nil
    end
  end

  class GatewayMessage
    JSON.mapping(t: String | Nil, s: Int64 | Nil, op: Opcode, d: JSON::Any)
  end

  enum Opcode
    DISPATCH
    HEARTBEAT
    IDENTIFY
    STATUS_UPDATE
    VOICE_STATE_UPDATE
    RESUME = 6
    RECONNECT
    REQUEST_GUILD_MEMBERS
    INVALID_SESSION
    HELLO
    HEARTBEAT_ACK
  end

  def send(msg)
    @ws.try {|ws| ws.send(msg.to_json)}
  end

  def send_identify; send({
    op: Opcode::IDENTIFY,
    d: {
      token: @token,
      properties: {
        "$os" => "unknown",
        "$device" => "lustrous",
        "$browser" => "lustrous"
      }
    }
  }) end

  def send_heartbeat; send({
    op: Opcode::HEARTBEAT,
    d: @seq
  }) end

  def send_resume; send({
    op: Opcode::RESUME,
    d: {
      token: @token,
      session_id: @sid,
      seq: @seq
    }
  }) end
end