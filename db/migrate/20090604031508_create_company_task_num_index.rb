class CreateCompanyTaskNumIndex < ActiveRecord::Migration
  def self.up
    add_index(:tasks, [ :task_num, :company_id ], :unique => true)
  end

  def self.down
    remove_index(:tasks, [ :task_num, :company_id ])
  end
end
