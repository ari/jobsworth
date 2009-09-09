class TodosController < ApplicationController
  before_filter :load_task

  def create
    @todo = @task.todos.build(params[:todo])
    @todo.creator_id = current_user.id
    @todo.save

    render :partial => "todos"
  end

  def update
    @todo = @task.todos.find(params[:id])
    @todo.update_attributes(params[:todo])

    render :partial => "todos"
  end

  def toggle_done
    @todo = @task.todos.find(params[:id])

    if @todo.done?
      @todo.completed_at = nil
      @todo.completed_by_user = nil
    else
      @todo.completed_at = Time.now
      @todo.completed_by_user = current_user
    end

    @todo.save
    render :partial => "todos"
  end

  def destroy
    @todo = @task.todos.find(params[:id])
    @todo.destroy

    render :partial => "todos"
  end

  private

  def load_task
    @task = current_user.company.tasks.find(params[:task_id])

    if @task.nil? or !current_user.can_view_task?(@task)
      flash[:notice] = _("You don't have access to that task")
      redirect_from_last
    end
  end

end
