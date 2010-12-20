def formula(task)
  task.weight = (Time.now - task.created_at).to_i
end
