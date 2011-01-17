#!/usr/bin/env ruby
ENV["RAILS_ENV"] ||= "production"

require File.expand_path("../../../config/environment.rb", __FILE__)
require 'daemons'
require 'rufus/scheduler'
Daemons.run_proc('scheduler.rb') do
  scheduler = Rufus::Scheduler.start_new

  scheduler.every '1m' do
    Rails.logger.info "Processing mail queue..."
    EmailDelivery.cron
  end
  scheduler.join
end
