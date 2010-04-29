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
                 m = Milestone.find(self.filter_by[1..-1], :conditions => ["project_id IN (#{User.find(self.user_id).projects.collect(&:id).join(',')})"])
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
        start = time_zone.local_to_utc(tz.now.beginning_of_week.midnight - 5.weeks)
        step = 2
        interval = 1.week / step
        range = 6
        tick = _("Week") + " %W"
      when 180 then
        start = time_zone.local_to_utc(tz.now.beginning_of_month.midnight - 5.months)
        step = 4
        interval = 1.month / step
        range = 6
        tick = "%b"
    end
    return start, step, interval, range, tick
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
#  index_widgets_on_user_id  (user_id)
#  fk_widgets_company_id     (company_id)
#

