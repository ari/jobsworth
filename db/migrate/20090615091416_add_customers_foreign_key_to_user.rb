class AddCustomersForeignKeyToUser < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    foreign_key(:users, :customer_id, :customers)
    add_index(:users, :customer_id)
  end

  def self.down
    remove_foreign_key(:users, :customer_id, :customers)
    remove_index(:users, :customer_id)
  end
end
