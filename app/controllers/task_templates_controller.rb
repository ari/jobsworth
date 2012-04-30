# encoding: UTF-8
class TaskTemplatesController < TasksController
  def destroy
    @task_template = current_templates.detect { |template| template.id == params[:id].to_i }
    @task_template.destroy
    flash[:success] = _('Template was deleted.')
    redirect_to '/task_templates'
  end

  def new
    @template = true
    super
  end

  def edit
    @template = true
    super
  end

  def create_task
    @task = current_templates.find_by_task_num(params[:id])
    @template = false
    @new_task = true

    render 'tasks/new'
  end

protected
####  This methods inherited from TasksController.
####  They modifies behavior of TasksController actions: new, create, edit, update etc.
####  Please see design pattern Template Method.
  def current_company_task_new
    task=Template.new
    task.company=current_user.company
    return task
  end
  def controlled_model
    Template
  end
  def tasks_for_list
    Template.where(:company_id => current_user.company_id)
  end
  def big_fat_controller_method
    #must be empty, templates don't use all this stuff
  end
  def create_worklogs_for_tasks_create(files)
    #must be empty, templates not have worklogs
  end
  def set_last_task(task)
    #empty method
  end
end
