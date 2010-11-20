# encoding: UTF-8
module NotificationsHelper
  include TaskFilterHelper
  # Returns true if there is a user with the given email
  # who should be allowed to view task.
  def show_task_link?(task, email)
    user=task.company.users.by_email(email).first
    return (user and user.can_view_task?(task))
  end
end
