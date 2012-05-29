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
    (action_ids - params.map{ |attr| attr[:id].to_i}).each { |id| actions.destroy(id) }
    params.each do |attr|
      unless attr[:id].blank?
        attr.delete(:factory_id)
        actions.find(attr[:id]).update_attributes(attr)
      else
        actions << ActionFactory.find(attr.delete(:factory_id)).build(attr)
      end
    end
  end
  # Fires any triggers that apply to the given task and
  # fire_on time (create, update, etc)
  def self.fire(task, fire_on)
    triggers = task.company.triggers.where(:event_id => fire_on)
    match = "tasks.id = #{ task.id }"

    triggers.each do |trigger|
      if trigger.task_filter
        trigger.task_filter.user = task.creator if task.creator
        apply = (trigger.task_filter.count(match) > 0)
      else
        apply = true
      end
      if apply
        executes= trigger.actions.collect{|action| action.execute(task) }
        worklog = WorkLog.new
        worklog.for_task(task)
        worklog.body = "This task was updated by trigger\n"
        worklog.body << executes.join(' ')
        worklog.save!

      end
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
#  created_at     :datetime
#  updated_at     :datetime
#  event_id       :integer(4)
#

