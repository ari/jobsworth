class MakeUuidAndAutologinNotNullInDb < ActiveRecord::Migration
  def self.up
    change_column_null(:users, :uuid, false)
    change_column_null(:users, :autologin, false)
  end

  def self.down
  end
end
