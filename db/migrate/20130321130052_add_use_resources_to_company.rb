class AddUseResourcesToCompany < ActiveRecord::Migration
  def change
    add_column :companies, :use_resources, :boolean, :default => true
  end
end
