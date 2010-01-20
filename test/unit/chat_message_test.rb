require File.dirname(__FILE__) + '/../test_helper'

class ChatMessageTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end

# == Schema Information
#
# Table name: chat_messages
#
#  id         :integer(4)      not null, primary key
#  chat_id    :integer(4)
#  user_id    :integer(4)
#  body       :string(255)
#  created_at :datetime
#  updated_at :datetime
#  archived   :boolean(1)      default(FALSE)
#

