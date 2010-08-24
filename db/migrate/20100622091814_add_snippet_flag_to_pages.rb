class AddSnippetFlagToPages < ActiveRecord::Migration
  def self.up
    add_column :pages, :snippet, :boolean, :default => false
  end

  def self.down
    remove_column :pages, :snippet
  end
end
