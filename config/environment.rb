# Load the rails application
require File.expand_path('../application', __FILE__)

require File.expand_path('../environment.local.rb', __FILE__) if File.exist?(File.expand_path('../environment.local.rb', __FILE__))

# Initialize the rails application
Jobsworth::Application.initialize!
