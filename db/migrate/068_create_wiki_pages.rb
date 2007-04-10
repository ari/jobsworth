class CreateWikiPages < ActiveRecord::Migration

  def self.up
    create_table :wiki_pages do |t|
      t.column :company_id, :integer
      t.column :project_id, :integer

      t.column :created_at, :timestamp
      t.column :updated_at, :timestamp

      t.column :name, :string

      t.column :locked_at, :timestamp
      t.column :locked_by, :integer
    end

    add_index :wiki_pages, :company_id

    create_table :wiki_revisions do |t|
      t.column :wiki_page_id, :integer
      t.column :created_at, :timestamp
      t.column :updated_at, :timestamp
      t.column :body, :text
      t.column :user_id, :integer
    end

    add_index :wiki_revisions, :wiki_page_id

  end

  def self.down
    drop_table :wiki_revisions
    drop_table :wiki_pages
  end
end
