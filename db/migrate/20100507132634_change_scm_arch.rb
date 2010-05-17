require 'migration_helpers'

class ChangeScmArch < ActiveRecord::Migration
  extend MigrationHelpers
  def self.up
    drop_table :scm_revisions

    remove_column :scm_files, :commit_date
    remove_foreign_key(:scm_files, :company_id, :company)
    remove_column :scm_files, :company_id
    remove_column :scm_files, :project_id
    remove_column :scm_files, :name
    add_column :scm_files, :scm_changeset_id, :integer
    add_index :scm_files, :scm_changeset_id

		remove_foreign_key(:scm_changesets, :company_id, :company)
    remove_column :scm_changesets, :company_id
    remove_column :scm_changesets, :project_id
    add_column :scm_changesets, :scm_files_count, :integer
  end

  def self.down
    create_table :scm_revisions do |t|
      t.column :company_id, :integer
      t.column :project_id, :integer
      t.column :user_id, :integer
      t.column :scm_changeset_id, :integer
      t.column :scm_file_id, :integer
      t.column :revision, :string
      t.column :author, :string
      t.column :commit_date, :timestamp
      t.column :state, :string
    end

    add_column :scm_files, :commit_date, :timestamp
    add_column :scm_files, :company_id, :integer
    add_column :scm_files, :project_id, :integer
    add_column :scm_files, :name, :string
    remove_index :scm_files, :scm_changeset_id
    remove_column :scm_files, :scm_changeset_id

    add_column :scm_changesets, :company_id, :integer
    add_column :scm_changesets, :project_id, :integer
    remove_column :scm_changesets, :scm_files_count
  end
end
