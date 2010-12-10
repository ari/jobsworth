class DropEmails < ActiveRecord::Migration
  def self.up
    drop_table :emails
  end

  def self.down
    create_table :emails do |t|
      t.string :from
      t.string :to
      t.string :subject
      t.text   :body

      t.integer :company_id
      t.integer :user_id

      t.timestamps
    end
  end
end
