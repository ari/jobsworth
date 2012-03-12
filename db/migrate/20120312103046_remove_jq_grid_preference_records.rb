class RemoveJqGridPreferenceRecords < ActiveRecord::Migration
  def up
    Preference.delete("preferences.key" => "tasklistcols")
  end

  def down
  end
end
