require "test_helper"

class TodoTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end






# == Schema Information
#
# Table name: todos
#
#  id                   :integer(4)      not null, primary key
#  task_id              :integer(4)
#  name                 :string(255)
#  position             :integer(4)
#  creator_id           :integer(4)
#  completed_at         :datetime
#  created_at           :datetime
#  updated_at           :datetime
#  completed_by_user_id :integer(4)
#
# Indexes
#
#  index_todos_on_task_id  (task_id)
#

