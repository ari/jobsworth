# encoding: UTF-8
class EmailAddress < ActiveRecord::Base
  belongs_to :user
  has_many :email_deliveries
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
  
end
