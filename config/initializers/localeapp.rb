if defined?(Localeapp)
  require 'localeapp/rails'

  if Setting.localeapp!.api_key.present?
    Localeapp.configure do |config|
      config.api_key = Setting.localeapp.api_key
      config.sending_environments   = Setting.localeapp.sending_environments.to_a
      config.polling_environments   = Setting.localeapp.polling_environments.to_a
      config.reloading_environments = Setting.localeapp.reloading_environments.to_a
    end
  end
end
