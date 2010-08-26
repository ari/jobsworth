class TodosController < ApplicationController
  before_filter :load_task, :except => [:list_clone, :create_clone, :update_clone, :destroy_clone, :toggle_todo_clone_done]

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
      @todo.completed_by_user_id = nil
    else
      @todo.completed_at = Time.now
      @todo.completed_by_user_id = current_user.id
    end

    @todo.save
    render :partial => "todos"
  end

  def destroy
    @todo = @task.todos.find(params[:id])
    @todo.destroy

    render :partial => "todos"
  end

  def reorder
    params[:todos].values.each{ |todo| t=@task.todos.find(todo[:id]); t.position=todo[:position]; t.save!}
    render :nothing=>true
  end

  #TODOS clone : for todos at task creation page (from template)
  def list_clone
    session[:todos_clone] = Template.find(params[:id]).clone_todos
    session[:todos_clone].collect{|t| t.completed_by_user = nil}

    render :partial => "todos_clone"
  end

  def create_clone
    @todo = Todo.new(params[:todo])
    @todo.creator_id = current_user.id
    @todo.position = session[:todos_clone].size + 1
    session[:todos_clone] << @todo
   
    render :partial => "todos_clone"
  end

  def update_clone
    session[:todos_clone].each{|t| t.name = params[:todo][:name] if t.position == params[:id].to_i}
     
    render :partial => "todos_clone"
  end
  
  def toggle_todo_clone_done
    session[:todos_clone].each do |t|
      if t.position == params[:id].to_i
        @todo = t
        break
      end
    end
    @todo.completed_at = @todo.done? ? nil : @todo.completed_at = Time.now
    
    render :partial => "todos_clone"
  end

  def destroy_clone
    size = session[:todos_clone].size
    session[:todos_clone].delete_if{|x| x.position == params[:id].to_i}
    session[:todos_clone].each do |t|
      p = t.position
      t.position = p -1 if t.position > params[:id].to_i
    end

    render :partial => "todos_clone"
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
