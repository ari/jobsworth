class ChangeAccessLevelNames < ActiveRecord::Migration
  def self.up
    access_level=  AccessLevel.find_by_name('customer')
    access_level.name='public'
    access_level.save!

    access_level= AccessLevel.find_by_name('internal')
    access_level.name='private'
    access_level.save!
  end

  def self.down
    access_level=  AccessLevel.find_by_name('public')
    access_level.name='customer'
    access_level.save!

    access_level= AccessLevel.find_by_name('public')
    access_level.name='internal'
    access_level.save!
  end
end
