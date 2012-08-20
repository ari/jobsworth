class CreateWorkPlans < ActiveRecord::Migration
  def change
    create_table :work_plans do |t|
      t.decimal :monday, :precision => 1, :default => 8.0
      t.decimal :tuesday, :precision => 1, :default => 8.0
      t.decimal :wednesday, :precision => 1, :default => 8.0
      t.decimal :thursday, :precision => 1, :default => 8.0
      t.decimal :friday, :precision => 1, :default => 8.0
      t.decimal :saturday, :precision => 1, :default => 0.0
      t.decimal :sunday, :precision => 1, :default => 0.0
      t.integer :user_id

      t.timestamps
    end

    add_index :work_plans, :user_id

    User.all.each do |u|
      u.create_work_plan!
    end
  end
end
