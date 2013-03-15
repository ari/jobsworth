# Load the rails application
require File.expand_path('../application', __FILE__)

# read config from application.yml if present
application_file = Rails.root.join("config", "application.yml")
Setting = if File.exists? application_file
  Hashie::Mash.new YAML.load(ERB.new(File.read(application_file)).result)[Rails.env]
else
  Hashie::Mash.new
end

# Some settings are required, assign them default values if not already present
required_settings_with_defaults = {
  :store_root       => Rails.root.join("store").to_s,
  :from             => 'fromnotset',
  :domain           => 'example.org',
  :receiving_emails => { :secret => SecureRandom.hex(8) }
}
required_settings_with_defaults.each { |key, value|
  unless Setting.key?(key)
    Setting[key] = value
    puts "WARNING: Could not find setting #{key.inspect} for #{Rails.env} environment in config/application.yml"
    puts "         Defaulting #{key.inspect} to #{Setting[key].inspect}"
  end
}

# read jenkins build version if it exists
version_file = Rails.root.join("config", "jenkins.build")
if File.exists? version_file
  Setting.version = File.read(version_file)
end

# Initialize the rails application
Jobsworth::Application.initialize!
