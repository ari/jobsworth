class AddGoogleGadgets < ActiveRecord::Migration
  def self.up
    add_column :widgets, :gadget_url, :text, :default => nil
  end

  def self.down
    remove_column :widgets, :gadget_url
  end
end
