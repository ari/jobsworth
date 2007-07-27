class ExceptionMigrationGenerator < Rails::Generator::NamedBase
  attr_reader :exception_table_name
  def initialize(runtime_args, runtime_options = {})
    @exception_table_name = (runtime_args.length < 2 ? 'logged_exceptions' : runtime_args[1]).tableize
    runtime_args << 'add_exception_table' if runtime_args.empty?
    super
  end

  def manifest
    record do |m|
      m.migration_template 'migration.rb', 'db/migrate'
    end
  end
end
