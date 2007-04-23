require 'drb'
require 'thread'
require 'yaml'
require 'erb'


module ActsAsFerret

module Remote

  module Config
    class << self
      DEFAULTS = {
        'host' => 'localhost',
        'port' => '9009'
      }
      # reads connection settings from config file
      def load(file = "#{RAILS_ROOT}/config/ferret_server.yml")
        config = DEFAULTS.merge(YAML.load(ERB.new(IO.read(file)).result))
        if config = config[RAILS_ENV]
          config[:uri] = "druby://#{config['host']}:#{config['port']}"
          return config
        end
      end
    end
  end

  # This class acts as a drb server listening for indexing and
  # search requests from models declared to 'acts_as_ferret :remote => true'
  #
  # Usage: 
  # - copy doc/ferret_server.yml to RAILS_ROOT/config and modify to suit
  # your needs.
  # - run script/ferret_server (in the plugin directory) via script/runner:
  # RAILS_ENV=production script/runner vendor/plugins/acts_as_ferret/script/ferret_server
  #
  # TODO: automate installation of files to script/ and config/
  class Server

    cattr_accessor :running

    def self.start(uri = nil)
      ActiveRecord::Base.allow_concurrency = true
      uri ||= ActsAsFerret::Remote::Config.load[:uri]
      DRb.start_service(uri, ActsAsFerret::Remote::Server.new)
      self.running = true
    end

    def initialize
      @logger = Logger.new("#{RAILS_ROOT}/log/ferret_server.log")
    end

    # handles all incoming method calls, and sends them on to the LocalIndex
    # instance of the correct model class.
    #
    # Calls are not queued atm, so this will block until the call returned.
    # Might throw the occasional LockError, too, which most probably means that you're 
    # a) rebuilding your index or 
    # b) have *really* high load. I wasn't able to reproduce this case until
    # now, if you do, please contact me.
    #
    # TODO: rebuild indexes in separate directory so no lock errors in these
    # cases.
    def method_missing(name, *args)
      clazz = args.shift.constantize
      begin
        @logger.debug "call index method: #{name} with #{args.inspect}"
        clazz.aaf_index.send name, *args
      rescue NoMethodError
        @logger.debug "no luck, trying to call class method instead"
        clazz.send name, *args
      end
    rescue
      @logger.error "ferret server error #{$!}\n#{$!.backtrace.join '\n'}"
      raise
    end

    def ferret_index(class_name)
      # TODO check if in use!
      class_name.constantize.aaf_index.ferret_index
    end

    # the main loop taking stuff from the queue and running it...
    #def run
    #end

  end
end
end
