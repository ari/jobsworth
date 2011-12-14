class RemoveRequestedByInTask < ActiveRecord::Migration
  def up
    remove_column :tasks, :requested_by
  end

  def down
    add_column :tasks, :requested_by, :string
  end
end
