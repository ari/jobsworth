# encoding: UTF-8
class Trigger < ActiveRecord::Base
  belongs_to :company
  belongs_to :task_filter
  validates_presence_of :company
  validates_presence_of :fire_on

  attr_protected :company_id

  attr_accessor :trigger_type, :count, :period, :tz

  # Fires any triggers that apply to the given task and
  # fire_on time (create, update, etc)
  def self.fire(task, fire_on)
    triggers = task.company.triggers.where(:fire_on => fire_on)
    match = "tasks.id = #{ task.id }"

    triggers.each do |trigger|
      trigger.task_filter.user = task.creator if task.creator
      apply = (trigger.task_filter.count(match) > 0)
      eval(trigger.action) if apply
    end
  end

  def task_filter_name
    task_filter.nil? ? "None" : task_filter.name
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

