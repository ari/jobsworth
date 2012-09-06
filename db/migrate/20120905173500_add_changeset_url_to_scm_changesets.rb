class AddChangesetUrlToScmChangesets < ActiveRecord::Migration
  def change
    add_column :scm_changesets, :changeset_url, :string, :default => '', :null => false
  end
end
