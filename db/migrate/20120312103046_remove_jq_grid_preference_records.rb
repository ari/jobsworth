class RemoveJqGridPreferenceRecords < ActiveRecord::Migration
  def up
    Preference.where(:key => 'tasklistcols').delete_all rescue nil
  end

  def down
  end
end
