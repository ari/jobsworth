require 'rufus/scheduler'

scheduler = Rufus::Scheduler.start_new

# Every morning at 6:17am
scheduler.cron '17 6 * * *' do
  Rails.logger.tagged "SCHEDULER" do
    Rails.logger.info "Expire hide_until tasks"
    TaskRecord.expire_hide_until
  end
end

# Schedule tasks every 10 minutes
scheduler.cron '*/10 * * * *' do
  Rails.logger.tagged "SCHEDULER" do
    User.schedule_tasks
  end
end

# Every morning at 6:43am
scheduler.cron '43 6 * * *' do
  Rails.logger.tagged "SCHEDULER" do
    Rails.logger.info "Recalculating score values for all the tasks"
    TaskRecord.calculate_score
  end
end
