class RemoveLoggedExceptionsTable < ActiveRecord::Migration
  def up
    drop_table :logged_exceptions
  end

  def down
  end
end
