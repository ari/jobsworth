class AddNotableToPages < ActiveRecord::Migration
  def self.up
    add_column :pages, :notable_id, :integer
    add_column :pages, :notable_type, :string

    add_index :pages, [ :notable_id, :notable_type ]
  end

  def self.down
    remove_column :pages, :notable_id
    remove_column :pages, :notable_type
  end
end
