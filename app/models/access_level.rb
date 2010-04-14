class AccessLevel < ActiveRecord::Base
  has_many :work_logs
  has_many :users

  validates_presence_of :name
end
