class CreateViews < ActiveRecord::Migration
  def self.up
    create_table :views do |t|
      t.column :name, :string
      t.column :company_id, :integer
      t.column :user_id, :integer
      t.column :shared, :integer, :default => 0
      t.column :auto_group, :integer, :default => 0
      t.column :filter_customer_id, :integer, :default => 0
      t.column :filter_project_id, :integer, :default => 0
      t.column :filter_milestone_id, :integer, :default => 0
      t.column :filter_user_id, :integer, :default => 0
      t.column :filter_tags, :string, :default => ""
      t.column :filter_status, :integer, :default => 0
      t.column :filter_type_id, :integer, :default => 0
   end
  end

  def self.down
    drop_table :views
  end
end
