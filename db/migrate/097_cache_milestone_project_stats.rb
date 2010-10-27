class CacheMilestoneProjectStats < ActiveRecord::Migration
  def self.up
    add_column :projects, :critical_count, :integer, :default => 0
    add_column :projects, :normal_count, :integer, :default => 0
    add_column :projects, :low_count, :integer, :default => 0

    add_column :milestones, :total_tasks, :integer, :default => 0
    add_column :milestones, :completed_tasks, :integer, :default => 0

    Project.all.each do |p|
      p.critical_count = Task.where("project_id = ? AND (severity_id + priority)/2 > 0  AND completed_at IS NULL", p.id).count
      p.normal_count = Task.where("project_id = ? AND (severity_id + priority)/2 = 0 AND completed_at IS NULL", p.id).count
      p.low_count = Task.where("project_id = ? AND (severity_id + priority)/2 < 0 AND completed_at IS NULL", p.id).count
      p.save
    end

    Milestone.all.each do |m|
      m.completed_tasks = Task.where("milestone_id = ? AND completed_at is not null", m.id).count
      m.total_tasks = Task.where("milestone_id = ?", m.id).count
      m.save
    end

  end

  def self.down
    remove_column :milestones, :total_tasks
    remove_column :milestones, :completed_tasks

    remove_column :projects, :critical_count
    remove_column :projects, :normal_count
    remove_column :projects, :low_count

  end
end
