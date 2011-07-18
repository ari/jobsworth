# encoding: UTF-8
class NewsItem < ActiveRecord::Base
end

# == Schema Information
#
# Table name: news_items
#
#  id         :integer(4)      not null, primary key
#  created_at :datetime
#  body       :text
#  portal     :boolean(1)      default(TRUE)
#

