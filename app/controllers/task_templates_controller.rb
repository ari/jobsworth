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
  def ajax_check
    raise Exception, CUSTOM_ERROR_MESSAGE
  end
  def updatelog
    raise Exception, CUSTOM_ERROR_MESSAGE
  end
  def update_sheet_info
     raise Exception, CUSTOM_ERROR_MESSAGE
  end
  def update_tasks
    raise Exception, CUSTOM_ERROR_MESSAGE
  end
  def update_work_log
    raise Exception, CUSTOM_ERROR_MESSAGE
  end
end
