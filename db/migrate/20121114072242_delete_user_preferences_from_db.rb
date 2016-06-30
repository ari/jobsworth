class DeleteUserPreferencesFromDb < ActiveRecord::Migration
  def up
    # delete all user preferences
    # NOTE: currently we only use it for grid, no worry
    Preference.where(:preferencable_type => 'User').delete_all
  end

  def down
  end
end
