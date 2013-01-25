# Load the rails application
require File.expand_path('../application', __FILE__)

# read config from application.yml
Setting = Hashie::Mash.new YAML.load(ERB.new(File.read(Rails.root.join("config", "application.yml"))).result)[Rails.env]

# WARNING: store_root is not set
unless Setting.store_root
  puts "WARNING: you should set :store_root in config/application.yml"
  Setting.store_root = Rails.root.join("store").to_s
  puts ":store_root defaults to " + Setting.store_root
end

# read jenkins build version if it exists
version_file = Rails.root.join("config", "jenkins.build")
if File.exists? version_file
  Setting.version = File.read(version_file)
end

# Initialize the rails application
Jobsworth::Application.initialize!
