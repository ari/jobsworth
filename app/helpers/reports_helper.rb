module ReportsHelper

  def total_amount_worked(logs)
    total = 0
    for log in logs 
      total += log.duration
    end
    total
  end 

  def total_task_worked(logs, task_id)
    total = 0
    for log in logs
      if log.task.id == task_id
        total += log.duration
      end 
    end 
    total
  end

end
