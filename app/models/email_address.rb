# encoding: UTF-8
class EmailAddress < ActiveRecord::Base
  belongs_to :user
  has_many :work_logs
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i

  def self.find_by_incoming_email(email)
    e = EmailAddress.find_by_email(email)
    e = EmailAddress.new(:email => email) if e.nil?
    e
  end
  
end
