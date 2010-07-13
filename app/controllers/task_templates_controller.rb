class TaskTemplatesController < TasksController
#this actions defined in TasksController but unused in TasksTemplatesController
#they never called, but if some code call one of them, we need to know
#TODO: all this actions must be changed in production
  CUSTOM_ERROR_MESSAGE="tasks_tempaltes don't have this action, only tasks have "
  def  auto_complete_for_resource_name
    raise Exception, CUSTOM_ERROR_MESSAGE
  end
  def resource
    raise Exception, CUSTOM_ERROR_MESSAGE
  end
  def dependency
    raise Exception, CUSTOM_ERROR_MESSAGE
  end
  def ajax_restore
    raise Exception, CUSTOM_ERROR_MESSAGE
  end
  def ajax_hide
    raise Exception, CUSTOM_ERROR_MESSAGE
  end
  def updatelog
    raise Exception, CUSTOM_ERROR_MESSAGE
  end
  def update_sheet_info
     raise Exception, CUSTOM_ERROR_MESSAGE
  end
  def update_work_log
    raise Exception, CUSTOM_ERROR_MESSAGE
  end
  # don't track unread status for templates
  def set_unread
    render :text => "", :layout => false
  end
  
  def destroy    
    @task_template = current_templates.detect { |template| template.id == params[:id].to_i }
    @task_template.destroy
    flash['notice'] = _('Template was deleted.')  
    redirect_to '/task_templates/list'
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
    Template.find(:all, :conditions=>{ :company_id=>current_user.company_id})
  end
  def big_fat_controller_method
    #must be empty, templates don't use all this stuff
  end
  def create_worklogs_for_tasks_create
    #must be empty, templates not have worklogs
  end
  def set_last_task(task)
    #empty method
  end
end
