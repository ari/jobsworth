require 'rufus/scheduler'

scheduler = Rufus::Scheduler.start_new

scheduler.cron "*/1 * * * *" do
  Rails.logger.tagged "SCHEDULER" do
    Rails.logger.info "If you're happy and you know it"
    Rails.logger.info "And you really want to show it"
    Rails.logger.info "Clap your hands"
    Rails.logger.info Time.now.inspect
  end
end
