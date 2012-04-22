# encoding: UTF-8
# An active worksheet, linked to a task and a user

class Sheet < ActiveRecord::Base
  belongs_to :task, :class_name=>"AbstractTask", :foreign_key=>'task_id'
  belongs_to :project
  belongs_to :user

  validates_presence_of :task
  validates_presence_of :project
  validates_presence_of :user

  def paused?
    self.paused_at != nil
  end

  def duration
    d = (Time.now.utc - created_at).to_i
    d = d - (Time.now.utc - paused_at).to_i unless paused_at.nil?
    d = d - paused_duration
  end

  def start_pause
    if paused?
      resume
    else
      self.paused_at = Time.now
    end
  end

  private
  def resume
    self.paused_duration += (Time.now.utc - self.paused_at).to_i
    self.paused_at = nil
  end


end





# == Schema Information
#
# Table name: sheets
#
#  id              :integer(4)      not null, primary key
#  user_id         :integer(4)      default(0), not null
#  task_id         :integer(4)      default(0), not null
#  project_id      :integer(4)      default(0), not null
#  created_at      :datetime
#  body            :text
#  paused_at       :datetime
#  paused_duration :integer(4)      default(0)
#
# Indexes
#
#  index_sheets_on_task_id  (task_id)
#  index_sheets_on_user_id  (user_id)
#

