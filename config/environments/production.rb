Jobsworth::Application.configure do
  # Settings specified here will take precedence over those in config/environment.rb

  config.eager_load = true

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Specifies the header that your server uses for sending files
 # config.action_dispatch.x_sendfile_header = "X-Sendfile"

  # For nginx:
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'

  # If you have no front-end server that supports something like X-Sendfile,
  # just comment this out and Rails will serve the files

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new
  config.log_level = :info

  if config.try(:jobsworth).try(:logstash_port).present? && config.try(:jobsworth).try(:logstash_host).present?
    config.logstash.progname = 'Jobsworth'
    config.logstash.formatter = :json_lines
    config.logstash.port = config.jobsworth.logstash_port
    config.logstash.type = :udp
    config.logstash.host = config.jobsworth.logstash_host
    config.logstash.ssl_enable = true
  end

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  config.serve_static_files = true
  config.assets.digest = true
  config.assets.compress = true
  config.assets.compile = false
  config.assets.js_compressor = Closure::Compiler.new if ENV['COMPILING_ASSETS']

  # Enable serving of images, stylesheets, and javascripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log
  config.cache_store = :file_store, config.jobsworth.cache_path
end
