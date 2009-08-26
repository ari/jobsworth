class AddUuidAndAutologinIfMissing < ActiveRecord::Migration
  def self.up
    User.all(:conditions => "autologin is null or uuid is null").each do |u|
      u.generate_uuid
      u.save!
    end
  end

  def self.down
  end
end
