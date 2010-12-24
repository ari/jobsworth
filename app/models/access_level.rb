# encoding: UTF-8
class AccessLevel < ActiveRecord::Base
  has_many :work_logs
  has_many :users

  validates_presence_of :name
end

# == Schema Information
#
# Table name: access_levels
#
#  id         :integer(4)      not null, primary key
#  name       :string(255)
#  created_at :datetime
#  updated_at :datetime
#

