class TruncateSessionTable < ActiveRecord::Migration
  def up
    execute <<-SQL
      delete from sessions
    SQL
  end

  def down
  end
end
