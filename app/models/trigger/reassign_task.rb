# encoding: UTF-8
class Trigger::ReassignTask < Trigger::Action
  def user=(user_or_id)
    self.argument= user_or_id.is_a?(User) ? user_or_id.id : id
  end

  def user
    @user ||= User.find(argument)
  end

  def user_id
    argument
  end

  def user_id=(id)
    self.argument=id
  end

  def execute(task)
    owners= task.owners - task.watchers
    task.owners = [user]
    task.watchers<< owners
    task.save!
    return "- Assignment: #{task.owners_to_display}\n"
  end
end
