class QueuesController < ApplicationController
  def index
    @tasks=TasksQueue.tasks_for_user(current_user)
  end

  def calculate
    if params[:id]
      TasksQueue.calculate_one(Task.accessed_by(current_user).find_by_task_num(params[:id]))
    else
      TasksQueue.calculate(current_user.company)
    end
    redirect_to :action=> :index
  end
end
