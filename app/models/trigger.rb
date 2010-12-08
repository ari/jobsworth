# encoding: UTF-8
class Trigger < ActiveRecord::Base
  belongs_to :company
  belongs_to :task_filter
  has_many   :actions
  validates_presence_of :company
  validates_presence_of :event_id

  attr_protected :company_id

  attr_accessor :trigger_type, :count, :period, :tz

  def actions_attributes=(params)

  end
  # Fires any triggers that apply to the given task and
  # fire_on time (create, update, etc)
  def self.fire(task, fire_on)
    triggers = task.company.triggers.where(:event_id => 1)
    match = "tasks.id = #{ task.id }"

    triggers.each do |trigger|
      if trigger.task_filter
        trigger.task_filter.user = task.creator if task.creator
        apply = (trigger.task_filter.count(match) > 0)
      else
        apply = true
      end
      trigger.actions.each{ |action| action.execute(task) if (apply && action.is_a?(SetDueDate))}
    end
  end

  def task_filter_name
    task_filter.nil? ? "None" : task_filter.name
  end

  def event_name
    Event.find(event_id).name
  end
end

# == Schema Information
#
# Table name: triggers
#
#  id             :integer(4)      not null, primary key
#  company_id     :integer(4)
#  task_filter_id :integer(4)
#  fire_on        :text
#  action         :string(255)
#  created_at     :datetime
#  updated_at     :datetime
#

