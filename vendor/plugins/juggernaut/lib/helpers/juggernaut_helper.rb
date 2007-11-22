require "cgi"
CONFIG = Juggernaut.config

module ActionView
module Helpers
module JuggernautHelper

def flash_plugin(channels = ["default"])

host = CONFIG["PUSH_HELPER_HOST"]
port = CONFIG["PUSH_PORT"]
crossdomain = CONFIG["CROSSDOMAIN"]
juggernaut_data =  CGI.escape('"' + channels.join('","') + '"')

<<-"END_OF_HTML"
<script type="text/javascript">
juggernautInit();
</script>
<OBJECT classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000"
 codebase="http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=5,0,0,0"
 WIDTH="1" HEIGHT="1" id="myFlash" name="myFlash">
 <PARAM NAME=movie VALUE="/socket_server.swf?host=#{host}&port=#{port}&crossdomain=#{crossdomain}&juggernaut_data=#{juggernaut_data}"> <PARAM NAME=quality VALUE=high>
 <EMBED src="/socket_server.swf?host=#{host}&port=#{port}&crossdomain=#{crossdomain}&juggernaut_data=#{juggernaut_data}" quality=high  WIDTH="1" HEIGHT="1" NAME="myFlash" swLiveConnect="true" TYPE="application/x-shockwave-flash" PLUGINSPAGE="http://www.macromedia.com/go/getflashplayer"></EMBED>
</OBJECT>
END_OF_HTML
end

end
end
end
