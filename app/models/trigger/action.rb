# encoding: UTF-8
class Trigger::Action < ActiveRecord::Base
  attr_protected :type
  belongs_to :trigger

  def name
    self.attributes['name'] || self.class.name.demodulize.underscore.humanize
  end

  def execute(task)
    raise "Trigger::Action: Subclass should reimplement execute action"
  end
end

# == Schema Information
#
# Table name: trigger_actions
#
#  id         :integer(4)      not null, primary key
#  trigger_id :integer(4)
#  name       :string(255)
#  type       :string(255)
#  argument   :integer(4)
#  created_at :datetime
#  updated_at :datetime
#

