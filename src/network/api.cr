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

  private def fmtpath(path : String, args = {} of String => JSON::Any)
    newp = path
    args.select {|k,v| path.includes? "%#{k}%"}.each do |key, value|
      newp = newp.gsub("%#{key}%", value.to_s)
    end

    {newp, args.reject {|k,v| path.includes? "%#{k}%"}}
  end

  private macro endpoint(name, method, path, *args)
    def {{name.id}}({{*args}})
      request(HttpMethod::{{method.id}}, {{path}},
        {% if !args.empty? %} { {% for arg in args %} "{{arg.var}}" => {{arg.var}} {% end %} } {% end %})
    end
  end

  endpoint get_gateway,     GET, "/gateway"
  endpoint get_gateway_bot, GET, "/gateway/bot"
end