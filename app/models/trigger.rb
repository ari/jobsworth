class Trigger < ActiveRecord::Base
  belongs_to :company
  belongs_to :task_filter
  validates_presence_of :company
  validates_presence_of :fire_on

  # Fires any triggers that apply to the given task and
  # fire_on time (create, update, etc)
  def self.fire(task, fire_on)
    triggers = task.company.triggers.all(:conditions => { :fire_on => fire_on })
    match = "tasks.id = #{ task.id }"

    triggers.each do |trigger|
      apply = (trigger.task_filter.count(match) > 0)
      eval(trigger.action) if apply
    end
  end
end
