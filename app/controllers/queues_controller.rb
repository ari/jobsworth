class QueuesController < ApplicationController
  def index
    @tasks=TasksQueue.tasks_for_user(current_user)
  end

  def calculate
    TasksQueue.calculate(current_user)
    redirect_to :action=> :index
  end
end
