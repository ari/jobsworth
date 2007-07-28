class AddNewsletterOption < ActiveRecord::Migration
  def self.up
    add_column :users, :newsletter, :integer, :default => 1
    execute('UPDATE users set newsletter = 1')
  end

  def self.down
    remove_column :users, :newsletter
  end
end
