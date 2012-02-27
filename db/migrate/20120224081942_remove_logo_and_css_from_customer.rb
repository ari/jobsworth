class RemoveLogoAndCssFromCustomer < ActiveRecord::Migration
  def change
    remove_column :customers, :logo_file_name
    remove_column :customers, :logo_content_type
    remove_column :customers, :logo_file_size
    remove_column :customers, :logo_updated_at
    remove_column :customers, :css
  end
end
