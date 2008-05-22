class AddCompanySettings < ActiveRecord::Migration
  def self.up
    add_column :companies, :show_wiki, :boolean, :default => true
    add_column :companies, :show_forum, :boolean, :default => true
    add_column :companies, :show_chat, :boolean, :default => true
  end

  def self.down
    remove_column :companies, :show_chat
    remove_column :companies, :show_forum
    remove_column :companies, :show_wiki
  end
end
