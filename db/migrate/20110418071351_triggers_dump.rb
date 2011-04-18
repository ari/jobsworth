class TriggersDump < ActiveRecord::Migration
  def self.up
    db_config = YAML::load(File.read(RAILS_ROOT + "/config/database.yml"))
    mysql=db_config[Rails.env]
    system("mysqldump -u#{mysql['username']} -p#{mysql['password']} #{mysql['database']} triggers trigger_actions --host=#{mysql['host']} > #{Rails.root}/db/triggers_dump.sql")
    Trigger.destroy_all
    Trigger::Action.destroy_all
  end

  def self.down
    db_config = YAML::load(File.read(RAILS_ROOT + "/config/database.yml"))
    mysql=db_config[Rails.env]
    system("mysql -u#{mysql['username']} -p#{mysql['password']} #{mysql['database']} --host=#{mysql['host']} < #{Rails.root}/db/triggers_dump.sql")
  end
end
