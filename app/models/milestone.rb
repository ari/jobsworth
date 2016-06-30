# encoding: UTF-8
# Logical grouping of tasks from one project.
#
# Can have a due date, and be completed

class Milestone < ActiveRecord::Base
  include Scorable

  STATUSES = [:planning, :open, :locked, :closed]

  belongs_to :company
  belongs_to :project
  belongs_to :user

  has_many :tasks, :class_name => 'TaskRecord', :dependent => :nullify
  validates :name, presence: true
  validates :project_id, presence: true

  after_save do |r|
    r.delay.calculate_score if r.status_changed?
    r.project.total_milestones = nil
    r.project.open_milestones = nil
    r.project.save
  end

  before_save do |m|
    if m.start_at && m.start_at > Time.now
      m.status_name = :planning
    end
    if m.locked? and m.tasks.open_only.count == 0
      m.status_name = :closed
      m.completed_at = Time.now
    end
  end

  scope :can_add_task, -> { where('status = ? OR status = ?', STATUSES.index(:planning), STATUSES.index(:open)) }
  scope :completed, -> { where('status = ?', STATUSES.index(:closed)) }
  scope :active, -> { where('status <> ?', STATUSES.index(:closed)) }
  scope :scheduled, -> { where('due_at IS NOT NULL') }
  scope :unscheduled, -> { where('due_at IS NULL') }
  scope :must_started_today, -> { where('status = ? AND start_at < ?', STATUSES.index(:planning), Time.now) }

  STATUSES.each do |s|
    define_method(s.to_s + '?') do
      self.status == STATUSES.index(s)
    end
  end

  def status_name
    self.status.nil? ? nil : STATUSES[self.status]
  end

  def status_name=(s)
    self.status = STATUSES.index(s)
  end

  def percent_complete
    return 0.0 if total_tasks == 0
    return (completed_tasks.to_f / total_tasks.to_f) * 100.0
  end

  # auto close milestone if milestone is locked and all tasks closed
  def update_status
    if self.locked? and self.tasks.open_only.count == 0
      self.update_attributes(:status_name => :closed, :completed_at => Time.now)
    end
  end

  def escape_twice(attr)
    h(String.new(h(attr)))
  end

  # TODO Does not belongs to here
  def to_tip(options = {})
    user = options[:user]
    utz = user.try :tz

    res = ''
    res << "<strong>#{I18n.t('milestones.name')}:</strong> #{escape_twice(self.name)}<br/>"
    res << "<strong>#{I18n.t('milestones.start_date')}:</strong> #{I18n.l(utz.utc_to_local(start_at), format: '%a, %d %b %Y')}<br/>" unless self.start_at.nil?
    res << "<strong>#{I18n.t('milestones.due_date')}:</strong> #{I18n.l(utz.utc_to_local(due_at), format: '%a, %d %b %Y')}<br/>" unless self.due_at.nil?
    res << "<strong>#{I18n.t('milestones.project')}:</strong> #{escape_twice(self.project.name)}<br/>"
    res << "<strong>#{I18n.t('milestones.client')}:</strong> #{escape_twice(self.project.customer.name)}<br/>"
    res << "<strong>#{I18n.t('milestones.owner')}:</strong> #{escape_twice(self.user.name)}<br/>" unless self.user.nil?
    res << "<strong>#{I18n.t('milestones.progress')}:</strong> #{self.completed_tasks.to_i} / #{self.total_tasks.to_i} #{I18n.t('milestones.complete')}<br/>"
    res
  end

  def due_date
    unless @due_date
      if due_at.nil?
        last = self.tasks.collect { |t| t.due_at.to_time.to_f if t.due_at }.compact.sort.last
        @due_date = Time.at(last).to_datetime if last
      else
        @due_date = due_at
      end
    end
    @due_date
  end

  def worked_minutes
    if @minutes.nil?
      @minutes = WorkLog.joins("INNER JOIN tasks ON tasks.milestone_id = #{self.id}").where('work_logs.task_id = tasks.id AND tasks.completed_at IS NULL').sum('work_logs.duration').to_i || 0
      @minutes /= 60
    end
    @minutes
  end

  def duration
    if @duration.nil?
      @duration = TaskRecord.where('tasks.milestone_id = ? AND tasks.completed_at IS NULL', self.id).sum(:duration).to_i || 0
    end
    @duration
  end

  def update_counts
    self.completed_tasks = TaskRecord.where('milestone_id = ? AND completed_at is not null', self.id).count
    self.total_tasks = TaskRecord.where('milestone_id = ?', self.id).count
    self.save
  end

  def to_s
    name + " (#{project.name})"
  end

  def current?
    start_at.present? && due_at.present? && Date.today.between?(start_at, due_at) ? true : false
  end

  private

  def calculate_score
    self.tasks.each do |t|
      t.calculate_score
      t.save
    end
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

