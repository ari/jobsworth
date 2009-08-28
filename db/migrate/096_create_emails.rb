class CreateEmails < ActiveRecord::Migration
  def self.up
    create_table :emails do |t|
      t.string :from
      t.string :to
      t.string :subject
      t.text   :body

      t.integer :company_id
      t.integer :user_id

      t.timestamps
    end

    add_column :event_logs, :user, :string

  end

  def self.down
    remove_column :event_logs, :user

    drop_table :emails
  end
end
