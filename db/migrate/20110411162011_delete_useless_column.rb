class DeleteUselessColumn < ActiveRecord::Migration
  def self.up
  User.all.each do |user|
    user.password = user[:password]
    user.password_confirmation = user[:password]
    user.save(:validate => false)
  end

  remove_column :users, :email
  remove_column :users, :password
  end

  def self.down
    add_column :users, :password, :string
    add_column :users, :email, :string
  end
end
