class AddTasksCompanyId < ActiveRecord::Migration
  def self.up
    add_column :tasks, :company_id, :integer

    @tasks = Task.all
    @tasks.each { |t| 
      t.company_id = t.user.company.id
      t.save
    }
  end

  def self.down
    remove_column :tasks, :company_id
  end
end
