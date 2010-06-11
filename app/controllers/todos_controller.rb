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
    params[:todo].delete(:done)
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
    @task = Task.accessed_by(current_user).find_by_id(params[:task_id])
    ###################### code smell begin ################################################################
    # this code allow usage  TodosController in TaskTemplatesController#edit
    #NOTE: Template is a Task, using single table inheritance
    if @task.nil?
      @task= Template.find_by_id(params[:task_id], :conditions=>["company_id = ?", current_user.company_id])
    end
    ###################### code smell end ##################################################################
    if @task.nil?
      flash[:notice] = _("You don't have access to that task")
      redirect_from_last
    end
  end

end
