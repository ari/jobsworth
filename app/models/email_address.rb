# encoding: UTF-8
class EmailAddress < ActiveRecord::Base
  belongs_to :user
  has_many :email_deliveries
  has_and_belongs_to_many :abstract_tasks, :join_table=>'email_address_tasks', :association_foreign_key=>'task_id'
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i

end
