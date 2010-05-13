class AddSecretKeyToScmProject < ActiveRecord::Migration
  def self.up
    add_column :scm_projects, :secret_key, :string, :unique=>true
  end

  def self.down
    remove_column :scm_projects, :secret_key
  end
end
