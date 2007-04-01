require "base64"
require "yaml"
require "socket"

module Juggernaut
FS_APP_CONFIG = YAML::load(File.open("#{RAILS_ROOT}/config/juggernaut_config.yml"))

def self.config
	return FS_APP_CONFIG
end

def self.send(data,chan = ["default"])
    @socket = TCPSocket.new(FS_APP_CONFIG["PUSH_HOST"], FS_APP_CONFIG["PUSH_PORT"])
    fc = { :message => Base64.encode64(data).gsub(/\n/,''), :secret => FS_APP_CONFIG["PUSH_SECRET"], :broadcast => 1, :channels => chan}
    @socket.print fc.to_json + "\0"
    @socket.flush
    @socket.close
 rescue
    false
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
