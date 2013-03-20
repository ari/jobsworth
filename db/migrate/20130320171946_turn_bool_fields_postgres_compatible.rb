class TurnBoolFieldsPostgresCompatible < ActiveRecord::Migration
  def up
    if ActiveRecord::Base.connection.instance_of? ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
      change_column_default(:users, :receive_notifications, nil)
      execute("ALTER TABLE users ALTER COLUMN receive_notifications TYPE boolean USING CASE WHEN receive_notifications = 0 THEN false ELSE TRUE END")
      change_column_default(:users, :receive_notifications, true)
    end
  end

  def down
    if ActiveRecord::Base.connection.instance_of? ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
      change_column_default(:users, :receive_notifications, nil)
      execute("ALTER TABLE users ALTER COLUMN receive_notifications TYPE integer USING CASE WHEN receive_notifications = false THEN 0 ELSE 1 END")
      change_column_default(:users, :receive_notifications, 1)
    end
  end
end
