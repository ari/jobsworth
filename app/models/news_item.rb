# encoding: UTF-8

# == Schema Information
#
# Table name: news_items
#
#  id         :integer(4)      not null, primary key
#  created_at :datetime
#  body       :text
#  portal     :boolean(1)      default(TRUE)
#

class NewsItem < ActiveRecord::Base
  attr_accessible :body, :portal

  default_scope :order => 'created_at DESC'

  validates :body,   :presence => true
  validates :portal, :presence => true
end
