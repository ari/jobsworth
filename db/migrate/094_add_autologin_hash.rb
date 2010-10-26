class AddAutologinHash < ActiveRecord::Migration
  def self.up
    add_column :users, :autologin, :string

    say_with_time("Generating autologin hashes..") do
      User.all.each do |u|
        u.autologin = Digest::MD5.hexdigest( rand(100000000).to_s + Time.now.to_s)
        u.save
      end
    end

    add_index :users, :autologin
  end

  def self.down
    remove_index :users, :autologin
    remove_column :users, :autologin
  end
end
