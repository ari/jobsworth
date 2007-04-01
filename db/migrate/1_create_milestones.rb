class CreateMilestones < ActiveRecord::Migration
  def self.up

    create_table :milestones do |t|
      t.column :company_id,     :integer
      t.column :project_id,     :integer
      t.column :user_id,     	:integer
      t.column :name,    	:string
      t.column :description,    :text
      t.column :due_at,   	:datetime
      t.column :position, 	:integer
    end

    add_column :tasks, 	:milestone_id, :integer

  end

  def self.down
    remove_column :tasks, :milestone_id
    drop_table :milestones
  end
end
