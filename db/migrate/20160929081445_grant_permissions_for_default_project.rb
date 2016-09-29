class GrantPermissionsForDefaultProject < ActiveRecord::Migration
  def change
    User.all.each do |user|
      project = user.company.default_project || user.company.projects.last
      current_permissions = user.project_permissions.where(project_id: project.id).first
      if current_permissions.present?
        current_permissions.set('create')
        current_permissions.set('edit')
        current_permissions.save!
      else
        new_permissions = user.project_permissions.new(project: project)
        new_permissions.set('create')
        new_permissions.set('edit')
        new_permissions.save!
      end
    end
  end
end