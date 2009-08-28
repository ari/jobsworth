require File.dirname(__FILE__) + '/../test_helper'

class ChatTest < ActiveSupport::TestCase
  fixtures :users

  def setup
    @chat = Chat.new(:user => User.first)
    @chat.save!
  end

  def test_unread_returns_unarchived_chat_messages
    assert_equal 0, @chat.unread

    assert @chat.chat_messages.create(:archived => 1)
    assert @chat.chat_messages.create(:archived => 2)
    assert @chat.chat_messages.create(:archived => 0)
    
    assert_equal 2, @chat.unread
  end
end
