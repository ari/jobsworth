class MigrationFromPasswordToEcnrytedPassword < ActiveRecord::Migration
  def self.up
    ActionDispatch::Callbacks.new(Proc.new {}, false).call({}) #Before actions below, we must reload environment
    User.all.each do |user|
      if user[:password] == nil
        user[:password] = ""
      end
    user.password = user[:password]
    user.password_confirmation = user[:password]
    user.save(:validate=>false)
  end
    remove_column :users, :password
  end
  def self.down
   add_column :users, :password, :string
  end
end
