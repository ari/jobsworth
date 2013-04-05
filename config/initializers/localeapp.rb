if defined?(Localeapp)
  require 'localeapp/rails'

  Localeapp.configure do |config|
    config.api_key = ENV['LOCALEAPP_TOKEN']
  end
end
