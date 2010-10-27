class CreateProjectPermissions < ActiveRecord::Migration
  def self.up
    create_table :project_permissions do |t|
       t.column :company_id, :integer
       t.column :project_id, :integer
       t.column :user_id, :integer
       t.column :created_at, :timestamp
    end

    projects = Project.all
    projects.each do |p|
      users = User.where("company_id = ?", p.company_id)
      users.each do |u|
        pm = ProjectPermission.new
	      pm.user_id = u.id
	      pm.project_id = p.id
	      pm.company_id = p.company_id
	      pm.save
      end
    end

    
  end

  def self.down
    drop_table :project_permissions
  end
end
