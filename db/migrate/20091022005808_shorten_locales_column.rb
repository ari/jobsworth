# Shorten column length so that the index isn't over 1000 chars when the collation is UTF8

class ShortenLocalesColumn < ActiveRecord::Migration
  def self.up
  	change_column :locales, :locale, :string, :limit => 6
  end

  def self.down
	change_column :locales, :locale, :string, :limit => 255
  end
end