class InitialScmModel < ActiveRecord::Migration

  def self.up
    create_table :scm_projects do |t|
      t.column :project_id, :integer
      t.column :company_id, :integer
      t.column :scm_type, :string
      t.column :last_commit_date, :timestamp
      t.column :last_update, :timestamp
      t.column :last_checkout, :timestamp
      t.column :module, :text
      t.column :location, :text
    end

    create_table :scm_files do |t|
      t.column :project_id, :integer
      t.column :company_id, :integer
      t.column :name, :text
      t.column :path, :text
      t.column :state, :string
      t.column :commit_date, :timestamp
    end

    create_table :scm_changesets do |t|
      t.column :company_id, :integer
      t.column :project_id, :integer
      t.column :user_id, :integer
      t.column :scm_project_id, :integer
      t.column :author, :string
      t.column :changeset_num, :integer
      t.column :commit_date, :timestamp
      t.column :changeset_rev, :string
      t.column :message, :text
    end

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

  end

  def self.down
    drop_table :scm_files
    drop_table :scm_revisions
    drop_table :scm_changesets
    drop_table :scm_projects
  end
end
