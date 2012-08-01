class AddCompanyIdToNewsItemsTable < ActiveRecord::Migration
  def change
    add_column :news_items, :company_id, :integer
  end
end
