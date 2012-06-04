# encoding: UTF-8
# A logical grouping of milestones and tasks, belonging to a Customer / Client

class Project < ActiveRecord::Base
  # Creates a score_rules association and updates the score
  # of all the task when adding a new score rule
  include Scorable

  belongs_to    :company
  belongs_to    :customer

  has_many      :users, :through => :project_permissions
  has_many      :project_permissions, :dependent => :destroy
  has_many      :pages, :as => :notable, :class_name => "Page", :order => "id desc", :dependent => :destroy
  has_many      :tasks
  has_many      :sheets, :dependent => :destroy
  has_many      :work_logs, :dependent => :destroy
  has_many      :project_files, :dependent => :destroy
  has_many      :project_folders, :dependent => :destroy
  has_many      :milestones, :dependent => :destroy, :order => "due_at asc, lower(name) asc"


  scope :completed, where("projects.completed_at is not NULL")
  scope :in_progress, where("projects.completed_at is NULL")
  scope :from_this_year, where("created_at > ?", Time.zone.now.beginning_of_year - 1.month)

  validates_length_of    :name,  :maximum=>200
  validates_presence_of  :name
  validates_presence_of  :customer

  validates :default_estimate,
            :presence      => true,
            :numericality  => { :greater_than_or_equal_to => 1.0 }

  after_update    :update_work_sheets
  before_destroy  :reject_destroy_if_have_tasks

  def copy_permissions_from(project_to_copy, user)
    project_to_copy.project_permissions.each do |perm|
      new_permission = perm.dup
      new_permission.project_id = id

      if new_permission.user_id == user.id
        new_permission.company_id = user.company_id
        new_permission.set('all')
      end

      new_permission.save
    end
  end

  def create_default_permissions_for(user)
    project_permission            = ProjectPermission.new
    project_permission.user_id    = user.id
    project_permission.project_id = id
    project_permission.company_id = user.company_id
    project_permission.set('all')
    project_permission.save
  end

  def has_users?
    company.users.size >= 1
  end

  def full_name
    "#{customer.name} / #{name}"
  end

  def to_s
    name
  end

  def to_css_name
    "#{self.name.underscore.dasherize.gsub(/[ \."',]/,'-')} #{self.customer.name.underscore.dasherize.gsub(/[ \.'",]/,'-')}"
  end

  def total_estimate
    tasks.sum(:duration).to_i
  end

  def work_done
    tasks.sum(:worked_minutes).to_i
  end

  def overtime
    tasks.where("worked_minutes > duration").sum('worked_minutes - duration').to_i
  end

  def total_tasks_count
    if self.total_tasks.nil?
       self.total_tasks = tasks.count
       self.save
    end
    total_tasks
  end

  def open_tasks_count
    if self.open_tasks.nil?
       self.open_tasks = tasks.where("completed_at IS NULL").count
       self.save
    end
    open_tasks
  end

  def total_milestones_count
    if self.total_milestones.nil?
       self.total_milestones = milestones.count
       self.save
    end
    total_milestones
  end

  def open_milestones_count
    if self.open_milestones.nil?
       self.open_milestones = milestones.where("completed_at IS NULL").count
       self.save
    end
    open_milestones
  end

  def progress
    done_percent = 0.0
    total_count = self.total_tasks_count * 1.0
    if total_count >= 1.0
      done_count = total_count - self.open_tasks_count
      done_percent = (done_count/total_count) * 100.0
    end
    done_percent
  end

  def completed_milestones_count
    total_milestones_count - open_milestones_count
  end

  ###
  # Updates the critical, normal and low counts for this project.
  # Also updates open and total tasks.
  ###
  def update_project_stats
    self.critical_count = tasks.where("task_property_values.property_value_id" => company.critical_values).includes(:task_property_values).count
    self.normal_count = tasks.where("task_property_values.property_value_id" => company.normal_values).includes(:task_property_values).count
    self.low_count = tasks.where("task_property_values.property_value_id" => company.low_values).includes(:task_property_values).count

    self.open_tasks = nil
    self.total_tasks = nil
  end

  private

  def reject_destroy_if_have_tasks
    unless tasks.count.zero?
      errors.add(:base, "Can not delete project, please remove tasks from this project.")
      return false
    end
    true
  end

  def update_work_sheets
    if self.customer_id != self.customer_id_was
      WorkLog.update_all("customer_id = #{self.customer_id}", 
        "project_id = #{self.id} AND customer_id != #{self.customer_id}")
    end
  end
end







# == Schema Information
#
# Table name: projects
#
#  id               :integer(4)      not null, primary key
#  name             :string(200)     default(""), not null
#  company_id       :integer(4)      default(0), not null
#  customer_id      :integer(4)      default(0), not null
#  created_at       :datetime
#  updated_at       :datetime
#  completed_at     :datetime
#  critical_count   :integer(4)      default(0)
#  normal_count     :integer(4)      default(0)
#  low_count        :integer(4)      default(0)
#  description      :text
#  open_tasks       :integer(4)
#  total_tasks      :integer(4)
#  total_milestones :integer(4)
#  open_milestones  :integer(4)
#  default_estimate :decimal(5, 2)   default(1.0)
#
# Indexes
#
#  projects_company_id_index   (company_id)
#  projects_customer_id_index  (customer_id)
#

