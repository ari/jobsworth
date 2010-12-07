# encoding: UTF-8
class Trigger::Action < ActiveRecord::Base
  attr_protected :type
  belongs_to :trigger

  def execute(task)
    raise "Subclass should reimplement execute action"
  end
end
