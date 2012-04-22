# encoding: UTF-8
# A widget on the Activities page.


class Widget < ActiveRecord::Base
  belongs_to :company
  belongs_to :user

  validates_presence_of :name

  def name
    res = ""
    if self.filter_by && self.filter_by.length > 0
      begin
        res << case self.filter_by[0..0]
               when 'c'
                 User.find(self.user_id).company.customers.find(self.filter_by[1..-1]).name
               when 'p'
                 User.find(self.user_id).projects.find(self.filter_by[1..-1]).name
               when 'm'
                 m = Milestone.where("project_id IN (?)", User.find(self.user_id).projects.collect(&:id)).find(self.filter_by[1..-1])
                 "#{m.project.name} / #{m.name}"
               when 'u'
                 _('[Unassigned]')
               else
                 ""
               end
      rescue
        res << _("Invalid Filter")
      end
    end
    res << " [#{_'Mine'}]" if self.mine?
    "#{@attributes['name']}#{ res.empty? ? "" : " - #{res}"}"
  end
  def calculate_start_step_interval_range_tick(time_zone)
    case self.number
      when 7 then
        start = time_zone.local_to_utc(6.days.ago.midnight)
        step = 1
        interval = 1.day / step
        range = 7
        tick = "%a"
      when 30 then
        start = time_zone.local_to_utc(time_zone.now.beginning_of_week.midnight - 5.weeks)
        step = 2
        interval = 1.week / step
        range = 6
        tick = _("Week") + " %W"
      when 180 then
        start = time_zone.local_to_utc(time_zone.now.beginning_of_month.midnight - 5.months)
        step = 4
        interval = 1.month / step
        range = 6
        tick = "%b"
    end
    return start, step, interval, range, tick
  end
  def filter_from_filter_by
    return nil unless filter_by
    case filter_by[0..0]
    when 'c' then
      "AND tasks.project_id IN (#{user.projects.where("customer_id = ?", filter_by[1..-1]).collect(&:id).compact.join(',') } )"
    when 'p' then
      "AND tasks.project_id = #{filter_by[1..-1]}"
    when 'm' then
      "AND tasks.milestone_id = #{filter_by[1..-1]}"
    when 'u' then
      "AND tasks.project_id = #{filter_by[1..-1]} AND tasks.milestone_id IS NULL"
    else
      ""
    end
  end
  def last_completed
    if mine?
      user.tasks.where("completed_at IS NOT NULL #{filter_from_filter_by}").order("completed_at DESC").limit(number)
    else
      Task.accessed_by(user).where("tasks.completed_at IS NOT NULL #{filter_from_filter_by}").order("tasks.completed_at DESC").limit(number)
    end
  end
  def counts
    tz= user.tz
    start=tz.local_to_utc(tz.now.at_midnight)
    intervals= [[start, start+1.day],
                [start - 1.day, start],
                [start - 6.days, start + 1.day],
                [start - 29.days, start + 1.day]]
    counts = {:work=>[], :completed=>[], :created=>[]}
    if mine?
      intervals.each_with_index do |interval, index|
        counts[:work][index] = mine_work_logs_sum(interval.first, interval.second)
        counts[:completed][index] = mine_tasks_count_completed(interval.first, interval.second)
        counts[:created][index] = mine_tasks_count_created(interval.first, interval.second)
      end
    else
      intervals.each_with_index do |interval, index|
        counts[:work][index] = work_logs_sum(interval.first, interval.second)
        counts[:completed][index] = tasks_count_completed(interval.first, interval.second)
        counts[:created][index] = tasks_count_created(interval.first, interval.second)
      end
    end
    return counts
  end
private

  def tasks_count_created(start, stop)
    Task.accessed_by(user).where("tasks.created_at >= ? AND tasks.created_at < ? #{filter_from_filter_by}", start, stop).count
  end

  def tasks_count_completed(start, stop)
    Task.accessed_by(user).where("tasks.completed_at IS NOT NULL AND tasks.completed_at >= ? AND tasks.completed_at < ? #{filter_from_filter_by}", start, stop).count
  end

  def work_logs_sum(start, stop)
    WorkLog.joins(:task).where("tasks.project_id IN (?) AND started_at >= ? AND started_at < ? #{filter_from_filter_by}", user.project_ids, start, stop).sum('work_logs.duration').to_i / 60
  end
  def mine_tasks_count_created(start, stop)
    user.tasks.where("tasks.created_at >= ? AND tasks.created_at < ? #{filter_from_filter_by}", start, stop).count
  end
  def mine_tasks_count_completed(start, stop)
    user.tasks.where("tasks.completed_at IS NOT NULL AND tasks.completed_at >= ? AND tasks.completed_at < ? #{filter_from_filter_by}", start, stop).count
  end
  def mine_work_logs_sum(start, stop)
    WorkLog.joins(:task).where("user_id = ? AND started_at >= ? AND started_at < ? #{filter_from_filter_by}", user.id, start, stop).sum('work_logs.duration').to_i / 60
  end
end







# == Schema Information
#
# Table name: widgets
#
#  id          :integer(4)      not null, primary key
#  company_id  :integer(4)
#  user_id     :integer(4)
#  name        :string(255)
#  widget_type :integer(4)      default(0)
#  number      :integer(4)      default(5)
#  mine        :boolean(1)
#  order_by    :string(255)
#  group_by    :string(255)
#  filter_by   :string(255)
#  collapsed   :boolean(1)      default(FALSE)
#  column      :integer(4)      default(0)
#  position    :integer(4)      default(0)
#  configured  :boolean(1)      default(FALSE)
#  created_at  :datetime
#  updated_at  :datetime
#  gadget_url  :text
#
# Indexes
#
#  fk_widgets_company_id     (company_id)
#  index_widgets_on_user_id  (user_id)
#

