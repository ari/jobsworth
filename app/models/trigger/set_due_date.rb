# encoding: UTF-8
class Trigger::SetDueDate < Trigger::Action

  def days=(a)
    self.argument=a
  end

  def days
    argument
  end

  def execute(task)
    task.due_at = Time.now + days.days
    task.save!
  end
end
