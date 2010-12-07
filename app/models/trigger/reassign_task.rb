# encoding: UTF-8
class Trigger::ReassignTask < Trigger::Action
  def user=(user_or_id)
    self.argument= user_or_id.is_a?(User) ? user_or_id.id : id
  end

  def user
    @user ||= User.find(argument)
  end
end
