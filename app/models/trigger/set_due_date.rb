# encoding: UTF-8
class Trigger::SetDueDate < Trigger::Action

  def days=(a)
    self.argument=a
  end

  def days
    argument
  end

  def execute(task)
    task.due_at = Time.now.utc + days.days
    task.save!
    return  "- Due: #{task.due_at.strftime_localized("%A, %d %B %Y")}\n".html_safe
  end
end
