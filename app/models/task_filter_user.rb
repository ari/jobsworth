class TaskFilterUser < ActiveRecord::Base
  belongs_to :user
  belongs_to :task_filter
end





# == Schema Information
#
# Table name: task_filter_users
#
#  id             :integer(4)      not null, primary key
#  user_id        :integer(4)
#  task_filter_id :integer(4)
#  created_at     :datetime
#  updated_at     :datetime
#
# Indexes
#
#  index_task_filter_users_on_task_filter_id  (task_filter_id)
#  index_task_filter_users_on_user_id         (user_id)
#

