class TruncateSessionTable < ActiveRecord::Migration
  def up
    execute <<-SQL
      truncate table sessions
    SQL
  end

  def down
  end
end
