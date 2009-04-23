class ChangeViewColumnsToString < ActiveRecord::Migration
  def self.up
    change_column(:views, :filter_customer_id, :string)
    change_column(:views, :filter_project_id, :string)
    change_column(:views, :filter_milestone_id, :string)
    change_column(:views, :filter_user_id, :string)
    change_column(:views, :filter_status, :string)
  end

  def self.down
    change_column(:views, :filter_customer_id, :integer)
    change_column(:views, :filter_project_id, :integer)
    change_column(:views, :filter_milestone_id, :integer)
    change_column(:views, :filter_user_id, :integer)
    change_column(:views, :filter_status, :integer)
  end
end
