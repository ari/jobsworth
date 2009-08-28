class AddForumMonitorships < ActiveRecord::Migration
  def self.up
    add_column :monitorships, :monitorship_type, :string
    execute("UPDATE monitorships set monitorship_type='topic';")
    rename_column :monitorships, :topic_id, :monitorship_id
  end

  def self.down
    rename_column :monitorships, :monitorship_id, :topic_id
    remove_column :monitorships, :monitorship_type
  end

end
