#!/usr/bin/env ruby
ENV["RAILS_ENV"] ||= "production"
rails_load_path=File.expand_path("../../../config/environment.rb", __FILE__)
require 'daemons'
require 'rufus/scheduler'
Daemons.run_proc('scheduler.rb') do
  require rails_load_path
  scheduler = Rufus::Scheduler.start_new
  p Rails.logger
  scheduler.every '1m' do
    p Rails.logger
    Rails.logger.fatal "Processing mail queue..."
    EmailDelivery.cron
  end
  scheduler.join
end
