class AddWikiChangeSummary < ActiveRecord::Migration
  def self.up
    add_column :wiki_revisions, :change, :string
  end

  def self.down
    remove_column :wiki_revisions, :change
  end
end
