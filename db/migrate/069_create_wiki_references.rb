class CreateWikiReferences < ActiveRecord::Migration
  def self.up
    create_table :wiki_references do |t|
      # t.column :name, :string
      t.column :wiki_page_id, :integer
      t.column :referenced_name, :string
      t.column :created_at, :timestamp
      t.column :updated_at, :timestamp
    end
  end

  def self.down
    drop_table :wiki_references
  end
end
