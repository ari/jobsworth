# encoding: UTF-8
class EmailAddress < ActiveRecord::Base
  belongs_to :user
  has_many :work_logs
  has_and_belongs_to_many :abstract_tasks, :join_table=>'email_address_tasks', :association_foreign_key=>'task_id'

  validates_presence_of :email
  validates_uniqueness_of :email, :case_sensitive => false
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i

  def username_or_email
    user ? user.name : self.email
  end

  def link_to_user(id)
    self.user_id = id
    self.save
    abstract_tasks.each do |task|
      task.email_addresses.delete(self)
      task.watchers << self.user
    end
  end
end




# == Schema Information
#
# Table name: email_addresses
#
#  id         :integer(4)      not null, primary key
#  user_id    :integer(4)
#  email      :string(255)
#  default    :boolean(1)
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  fk_email_addresses_user_id  (user_id)
#

