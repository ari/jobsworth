require 'localeapp/rails'

if Setting.localeapp.api_key.present?
  Localeapp.configure do |config|
    config.api_key = Setting.localeapp.api_key
    config.sending_environments = Setting.localeapp.sending_environments
    config.polling_environments = Setting.localeapp.polling_environments
    config.reloading_environments = Setting.localeapp.reloading_environments
  end
end
