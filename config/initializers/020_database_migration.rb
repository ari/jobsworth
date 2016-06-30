
# Disabled by default, this allows running migrations automatically on application boot.
# Helpful in environments where running it from console is not an option or requires additional overhead.
# For example, if running as a Tomcat servlet, and config/application.yml uses $servlet_context.getInitParameter to read variables.
# Do note however, that when set to true, migrations will run _everytime_ application is initialised, even in rake tasks, including db:migrate.
if Setting.run_migrations_on_boot

  Rails.logger.info 'Running database migrations'

  # Can not do following, as it reloads the environment which results in following error
  #
  # #<Class:0x9c2732e>: undefined method `each' for nil:NilClass
  # register_javascript_expansion at /.../gems/actionpack-3.2.13/lib/action_view/helpers/asset_tag_helpers/javascript_tag_helpers.rb:69
  #                       Railtie at /.../gems/actionpack-3.2.13/lib/action_view/railtie.rb:29
  #                                   ... rest of stack trace
  #
  # This happens because railtie.rb:29 contains following, so the same config is nil on second reload
  #   app.config.action_view.delete(:javascript_expansions)

  # Jobsworth::Application.load_tasks
  # Rake::Task["db:migrate"].invoke

  # Load schema if database is new
  if ActiveRecord::Migrator.current_version.zero?
    Rails.logger.info 'First time. Loading schema.'
    load Rails.root.join('db', 'schema.rb').to_s

    Rails.logger.info 'Creating essential database records'
    #Preload locales as they do not seem to be loaded at this stage
    #and are required in User#generate_widgets
    I18n.load_path += Dir[Rails.root.join('config', 'locales', '*.{rb,yml}').to_s]
    load Rails.root.join('db', 'seeds_minimal.rb').to_s
  end

  # Invoke migrations directly
  ActiveRecord::Migration.verbose = true
  ActiveRecord::Migrator.migrations_paths = Rails.application.paths['db/migrate'].to_a
  ActiveRecord::Migrator.migrate(ActiveRecord::Migrator.migrations_paths)
end
