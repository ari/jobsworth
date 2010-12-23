class QueuesController < ApplicationController
  def index
    @tasks=TasksQueue.tasks_for_user(current_user)
  end

  def calculate
    TasksQueue.calculate(current_user.company)
    redirect_to :action=> :index
  end
end
