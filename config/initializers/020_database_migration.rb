
# Disabled by default, this allows running migrations automatically on application boot.
# Helpful in environments where running it from console is not an option or requires additional overhead.
# For example, if running as a Tomcat servlet, and config/application.yml uses $servlet_context.getInitParameter to read variables.
# Do note however, that when set to true, migrations will run _everytime_ application is initialised, even in rake tasks, including db:migrate.
if Setting.run_migrations_on_boot

  Rails.logger.info "Running database migrations"

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

  # Invoke migrations directly
  ActiveRecord::Migration.verbose = true
  ActiveRecord::Migrator.migrations_paths = Rails.application.paths['db/migrate'].to_a
  ActiveRecord::Migrator.migrate(ActiveRecord::Migrator.migrations_paths)
end
