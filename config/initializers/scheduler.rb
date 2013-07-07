module SchedulerInitializer
  extend self
  require 'rufus/scheduler'

  def scheduler_disabled?
    ENV['JOBSWORTH_DISABLE_SCHEDULER'].present?
  end

  def schedule_task
    Rails.logger.tagged "SCHEDULER" do
      yield
    end
  ensure
    ActiveRecord::Base.connection_pool.release_connection
  end

  def init
    if scheduler_disabled?
      Rails.logger.tagged "SCHEDULER" do
        Rails.logger.info "Scheduler is disabled"
      end
      return
    end

    scheduler = Rufus::Scheduler.start_new

    # Every morning at 6:17am
    scheduler.cron '17 6 * * *' do
      schedule_task do
        Rails.logger.info "Expire hide_until tasks"
        TaskRecord.expire_hide_until
      end
    end

    # Schedule tasks every 10 minutes
    scheduler.cron '*/10 * * * *' do
      schedule_task do
        User.schedule_tasks
      end
    end

    # Every morning at 6:43am
    scheduler.cron '43 6 * * *' do
      schedule_task do
        Rails.logger.info "Recalculating score values for all the tasks"
        TaskRecord.calculate_score
      end
    end
  end
end

SchedulerInitializer.init

