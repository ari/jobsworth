class AddDateFormat < ActiveRecord::Migration
  def self.up
    add_column :users, :date_format, :string
    add_column :users, :time_format, :string
    execute("UPDATE users set date_format = '%d/%m/%Y'")
    execute("UPDATE users set time_format = '%H:%M'")
  end

  def self.down
    remove_column :users, :date_format
    remove_column :users, :time_format
  end
end
