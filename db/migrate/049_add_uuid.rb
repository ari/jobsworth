class AddUuid < ActiveRecord::Migration
  def self.up
    add_column :users, :uuid, :string
    add_index :users, :uuid
    add_index :users, :username
    add_index :users, :company_id

    User.all.each do |u|
      u.uuid = MD5.hexdigest( (u.id * 100000000 + rand(100000000)).to_s + Time.now.to_s)
      u.save
    end
  end

  def self.down
    remove_index :users, :company_id
    remove_index :users, :username
    remove_index :users, :uuid
    remove_column :users, :uuid
  end
end
