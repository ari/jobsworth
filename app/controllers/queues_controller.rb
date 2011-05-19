class QueuesController < ApplicationController
  def index
    @tasks=Task.joins(:owners).
                where(:users => {:id => current_user}).
                order("(tasks.weight + tasks.weight_adjustment) DESC")
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
