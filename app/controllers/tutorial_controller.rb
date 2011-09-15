# Handles simple user tutorial
class TutorialController < ApplicationController

  # Simple tutorial, guiding the user through
  # * Creating a Project
  # * Creating a Task
  # * Adding a WorkLog
  # * Completing a Task
  # * Adding a User
  def welcome
    if user_has_completed_tutorial?
      # TODO: Move this to the user model
      current_user.update_attributes(:seen_welcome => 1)
      flash['notice'] = _('Tutorial completed. It will no longer be shown in the menu.')
    end
  end

  # Skip the tutorial
  def hide_welcome
    # TODO: Move this to the user model
    current_user.update_attributes(:seen_welcome => 1)
    flash['notice'] = _('Tutorial hidden. It will no longer be shown in the menu.')
    redirect_to root_path
  end

  protected

  # TODO: The tutorial progress should be stored using cookies, not the db
  # TODO could make use of a state machine
  def user_has_completed_tutorial?
    @projects_count  = current_projects.size

    @tasks_count = Task.where("company_id = ? AND project_id IN (?)", 
                          current_user.company_id, current_project_ids).
                        count

    @work_count = WorkLog.accessed_by(current_user).
                          where(:log_type=>EventLog::TASK_WORK_ADDED).
                          count

    @completed_count = Task.
      where("company_id = ? AND project_id IN (?) AND completed_at IS NOT NULL", 
        current_user.company_id, current_project_ids).
      count

    @users_count = User.where("company_id = ?", current_user.company_id).count

    @projects_count > 0 && @tasks_count > 0 && @work_count > 0 && @completed_count > 0 && @users_count > 1
  end
end
