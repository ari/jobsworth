class ScmIndexes < ActiveRecord::Migration
  def self.up
    add_index :scm_changesets, :commit_date
    add_index :scm_changesets, :author
    add_index :scm_revisions, :scm_changeset_id
    add_index :scm_revisions, :scm_file_id
    add_index :scm_files, :project_id
  end

  def self.down
    remove_index :scm_changesets, :commit_date
    remove_index :scm_changesets, :author
    remove_index :scm_revisions, :scm_changeset_id
    remove_index :scm_revisions, :scm_file_id
    remove_index :scm_files, :project_id
  end
end
