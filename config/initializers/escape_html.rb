# For faster and better (UTF-8 aware) html escaping
# http://github.com/brianmario/escape_utils

require 'escape_utils/html/rack' # to patch Rack::Utils
require 'escape_utils/html/erb' # to patch ERB::Util
require 'escape_utils/html/cgi' # to patch CGI

# Fix bug in rack
module Rack
  module Utils
    def escape(s)
      EscapeUtils.escape_url(s)
    end
  end
end