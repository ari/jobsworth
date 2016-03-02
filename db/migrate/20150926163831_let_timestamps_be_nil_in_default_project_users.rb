class LetTimestampsBeNilInDefaultProjectUsers < ActiveRecord::Migration

  def change
    change_column :default_project_users, :created_at, :datetime, null: true
    change_column :default_project_users, :updated_at, :datetime, null: true
  end
end
