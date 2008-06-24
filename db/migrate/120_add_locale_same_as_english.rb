class AddLocaleSameAsEnglish < ActiveRecord::Migration
  def self.up
    add_column :locales, :same, :boolean, :default => false
  end

  def self.down
    remove_column :locales, :same
  end
end
