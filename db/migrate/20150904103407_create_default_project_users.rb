class CreateDefaultProjectUsers < ActiveRecord::Migration
  def change
    create_table :default_project_users do |t|
      t.integer :project_id
      t.integer :user_id
      t.timestamps
    end
  end
end
