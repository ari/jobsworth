# encoding: UTF-8
# Logical grouping of tasks from one project.
#
# Can have a due date, and be completed

class Milestone < ActiveRecord::Base
  include Scorable

  belongs_to :company
  belongs_to :project
  belongs_to :user

  has_many :tasks, :dependent => :nullify
  validates_presence_of :name

  after_save { |r|
    r.project.total_milestones = nil
    r.project.open_milestones = nil
    r.project.save
  }

  scope :not_completed, where('completed_at IS ?', nil)
  scope :completed, where('completed_at IS NOT ?', nil)

  def percent_complete
    return 0.0 if total_tasks == 0
    return (completed_tasks.to_f / total_tasks.to_f) * 100.0
  end

  def complete?
    !self.completed_at.nil?
  end
  
  def escape_twice(attr)
    h(String.new(h(attr)))
  end
  def to_tip(options = { })
    res = "<table cellpadding=0 cellspacing=0>"
    res << "<tr><th>#{_('Name')}</th><td> #{escape_twice(self.name)}</td></tr>"
    res << "<tr><th>#{_('Due Date')}</th><td> #{options[:user].tz.utc_to_local(due_at).strftime_localized("%A, %d %B %Y")}</td></tr>" unless self.due_at.nil?
    res << "<tr><th>#{_('Project')}</th><td> #{escape_twice(self.project.name)}</td></tr>"
    res << "<tr><th>#{_('Client')}</th><td> #{escape_twice(self.project.customer.name)}</td></tr>"
    res << "<tr><th>#{_('Owner')}</th><td> #{escape_twice(self.user.name)}</td></tr>" unless self.user.nil?
    res << "<tr><th>#{_('Progress')}</th><td> #{self.completed_tasks.to_i} / #{self.total_tasks.to_i} #{_('Complete')}</td></tr>"
    res << "<tr><th>#{_('Description')}</th><td class=\"tip_description\">#{escape_twice(self.description_wrapped).gsub(/\n/, '<br/>').gsub(/\"/,'&quot;')}</td></tr>" unless self.description.blank?
    res << "</table>"
    res.gsub(/\"/,'&quot;')
  end

  def description_wrapped
    unless description.blank?
       truncate( word_wrap(self.description, :line_width => 80), :length => 1000)
    else
      nil
    end
  end

  def due_date
    unless @due_date
      if due_at.nil?
        last = self.tasks.collect{ |t| t.due_at.to_time.to_f if t.due_at }.compact.sort.last
        @due_date = Time.at(last).to_datetime if last
      else
        @due_date = due_at
      end
    end
    @due_date
  end

  def scheduled_date
    (self.scheduled? ? self.scheduled_at : self.due_at)
  end

  def worked_minutes
    if @minutes.nil?
      @minutes = WorkLog.joins("INNER JOIN tasks ON tasks.milestone_id = #{self.id}").where("work_logs.task_id = tasks.id AND tasks.completed_at IS NULL").sum('work_logs.duration').to_i || 0
      @minutes /= 60
    end
    @minutes
  end

  def duration
    if @duration.nil?
      @duration = Task.where("tasks.milestone_id = ? AND tasks.completed_at IS NULL AND tasks.scheduled = ?", self.id, false).sum(:duration).to_i || 0
      @duration += Task.where("tasks.milestone_id = ? AND tasks.completed_at IS NULL AND tasks.scheduled = ?", self.id, true).sum(:scheduled_duration).to_i || 0
    end
    @duration
  end

  def update_counts
     self.completed_tasks = Task.where("milestone_id = ? AND completed_at is not null", self.id).count
     self.total_tasks = Task.where("milestone_id = ?", self.id).count
     self.save

  end

  def to_s
    name + " (#{project.name})"
  end

end








# == Schema Information
#
# Table name: milestones
#
#  id              :integer(4)      not null, primary key
#  company_id      :integer(4)
#  project_id      :integer(4)
#  user_id         :integer(4)
#  name            :string(255)
#  description     :text
#  due_at          :datetime
#  position        :integer(4)
#  completed_at    :datetime
#  total_tasks     :integer(4)      default(0)
#  completed_tasks :integer(4)      default(0)
#  scheduled_at    :datetime
#  scheduled       :boolean(1)      default(FALSE)
#  updated_at      :datetime
#  created_at      :datetime
#
# Indexes
#
#  milestones_company_project_index  (company_id,project_id)
#  milestones_company_id_index       (company_id)
#  milestones_project_id_index       (project_id)
#  fk_milestones_user_id             (user_id)
#

