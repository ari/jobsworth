class ClientCss < ActiveRecord::Migration
  def self.up
    add_column :customers, :css, :text
  end

  def self.down
    remove_column :customers, :css
  end
end
