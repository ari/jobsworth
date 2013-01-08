#!/usr/bin/env ruby

ENV["RAILS_ENV"] ||= "production"
rails_load_path=File.expand_path("../../config/environment.rb", __FILE__)

require 'daemons'
require 'rufus/scheduler'

Daemons.run_proc('scheduler.rb') do
  require rails_load_path
  scheduler = Rufus::Scheduler.start_new
  logger = Logger.new(File.join(Rails.root,'log','scheduler.log'), 'monthly')
  logger.level = Logger::INFO
  logger.formatter = Logger::Formatter.new
  Rails.logger = logger

  # Every morning at 6:17am
  scheduler.cron '17 6 * * *' do
    Rails.logger.info "Expire hide_until tasks"
    TaskRecord.expire_hide_until
  end

  # Schedule tasks every 10 minutes
  scheduler.cron '*/10 * * * *' do
    User.schedule_tasks
  end

  # Every morning at 6:43am
  scheduler.cron '43 6 * * *' do
    Rails.logger.info "Recalculating score values for all the tasks"
    TaskRecord.calculate_score
  end

  scheduler.join
end
