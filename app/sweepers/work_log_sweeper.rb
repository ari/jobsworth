class WorkLogSweeper < ActionController::Caching::Sweeper
  observe WorkLog

  def after_update(log)
    expire_fragment(["task_json", log.task])
  end

  def after_create(log)
    expire_fragment(["task_json", log.task])
  end

  def after_destroy(log)
    expire_fragment(["task_json", log.task])
  end
end
