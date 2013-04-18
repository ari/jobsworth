# encoding: UTF-8
class Trigger::SetDueDate < Trigger::Action

  def days=(a)
    self.argument=a
  end

  def days
    argument
  end

  def execute(task)
    task.update_column(:due_at, Time.now.utc + days.days)
    return  "- Due: #{I18n.l(task.due_at, format: "%A, %d %B %Y")}\n".html_safe
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

