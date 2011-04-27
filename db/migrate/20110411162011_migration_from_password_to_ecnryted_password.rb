class MigrationFromPasswordToEcnrytedPassword < ActiveRecord::Migration
  def self.up
    ActionDispatch::Callbacks.new(Proc.new {}, false).call({}) #Before actions below, we must reload environment
    User.all.each do |user|
      if user[:password] == nil
        user[:password]=""
      end
    salt=Devise::Encryptors::Ssha.salt(Devise.stretches)
    user[:password_salt]=salt
    user[:encrypted_password]=Devise::Encryptors::Ssha.digest(user[:password], Devise.stretches,salt, Devise.pepper)
    user.save(:validate=>false)
  end
    remove_column :users, :password
  end
  def self.down
   add_column :users, :password, :string
  end
end
