# encoding: UTF-8
module AdminStatsHelper

  def total_count_for(table,dates,condition="created_at")
    case dates
    when "today"
      table.where("#{condition} > '#{tz.now.at_midnight.to_s(:db)}'").count
    when  "yesterday"
      table.where("#{condition} > '#{tz.now.yesterday.at_midnight.to_s(:db)}' AND created_at < '#{tz.now.at_midnight.to_s(:db)}'").count
    when  "this_week"
      table.where("#{condition} > '#{tz.now.beginning_of_week.at_midnight.to_s(:db)}'").count
    when  "last_week"
      table.where("#{condition} > '#{1.week.ago.beginning_of_week.at_midnight.to_s(:db)}' AND created_at < '#{tz.now.beginning_of_week.at_midnight.to_s(:db)}'").count
    when "this_month"
      table.where("#{condition} > '#{tz.now.beginning_of_month.at_midnight.to_s(:db)}'").count
    when "last_month"
      table.where("#{condition} > '#{1.month.ago.beginning_of_month.at_midnight.to_s(:db)}' AND created_at < '#{tz.now.beginning_of_month.at_midnight.to_s(:db)}'").count
    when "this_year"
      table.where("#{condition} > '#{tz.now.beginning_of_year.at_midnight.to_s(:db)}'").count
    else
      nil
    end
  end
end
