# Load the rails application
require File.expand_path('../application', __FILE__)

require File.expand_path('../environment.jruby.rb', __FILE__) if $servlet_context
require File.expand_path('../environment.local.rb', __FILE__) if File.exist?(File.expand_path('../environment.local.rb', __FILE__))

# WARNING: store_root is not set
unless $CONFIG[:store_root]
  puts "WARNING: you should set :store_root in config/environment.local.rb"
  $CONFIG[:store_root] = Rails.root.join("store").to_s
  puts ":store_root defaults to " + $CONFIG[:store_root]
end

# read config from application.yml
# TODO: later we should use application.yml to centralize all settings
Setting = Hashie::Mash.new $CONFIG.merge(YAML.load(ERB.new(File.read(Rails.root.join("config", "application.yml"))).result)[Rails.env])

# read jenkins build version if it exists
version_file = Rails.root.join("config", "jenkins.build")
if File.exists? version_file
  Setting.version = File.read(version_file)
end

# Initialize the rails application
Jobsworth::Application.initialize!
