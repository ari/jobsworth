class AddPagesIndexes < ActiveRecord::Migration
  def self.up
    add_index :pages, :company_id
  end

  def self.down
    remove_index :pages, :company_id
  end
end
