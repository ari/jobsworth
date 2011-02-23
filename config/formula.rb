def formula(task)
  task.weight = (Time.now - task.created_at).to_i

  task.weight_adjustment = -task.weight unless task.ready?
end
