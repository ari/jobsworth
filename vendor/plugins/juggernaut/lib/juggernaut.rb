require "base64"
require "yaml"
require "socket"

module Juggernaut

def self.config
  if @config.nil?
    file = "#{RAILS_ROOT}/config/juggernaut_config.yml"
    if File.exists?(file)
      @config = YAML::load_file(file)
    else
      port = ENV["PUSH_PORT"]
      domain = ENV["PUSH_DOMAIN"]
      secret = ENV["PUSH_SECRET"]

      @config = {
        "PUSH_PORT" => port,
        "PUSH_HOST" => "0.0.0.0",
        "PUSH_HELPER_HOST" => "www.#{ domain }",
        "PUSH_SECRET" => secret,
        "CROSSDOMAIN" => "xmlsocket://www.#{ domain }:#{ port }",
        "ALLOW_CROSSDOMAIN" => "*.#{ domain }"
      }
    end
  end

  return @config
end

def self.send(data,chan = ["default"])
  begin
    @socket = TCPSocket.new(config["PUSH_HOST"], config["PUSH_PORT"])
    fc = { :message => data, :secret => config["PUSH_SECRET"], :broadcast => 1, :channels => chan}
    @socket.print fc.to_json + "\0"
    @socket.flush
  rescue
    puts "Error in Juggernaut#send: #{ $! }"
  ensure
    @socket.close if @socket and !@socket.closed?
  end 
end

    def self.html_escape(s)
        s.to_s.gsub(/&/, "&amp;").gsub(/\"/, "&quot;").gsub(/>/, "&gt;").gsub(/</, "&lt;")
    end

    def self.string_escape(s)
        s.gsub(/[']/, '\\\\\'')
    end

    def self.parse_string(s)
        s.gsub(/\r\n|\n|\r/, "\\n").gsub(/["']/) { |m| "\\#{m}" }
    end

    def self.html_and_string_escape(s)
       i = s.gsub(/[']/, '\\\\\'')
       i.to_s.gsub(/&/, "&amp;").gsub(/\"/, "&quot;").gsub(/>/, "&gt;").gsub(/</, "&lt;")
    end

end

#ActionView::Base::load_helpers
