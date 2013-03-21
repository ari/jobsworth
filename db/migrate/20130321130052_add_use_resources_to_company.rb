class AddUseResourcesToCompany < ActiveRecord::Migration
  def change
    add_column :companies, :allow_resources, :boolean, :default => true
  end
end
