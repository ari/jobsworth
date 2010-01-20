require File.dirname(__FILE__) + '/../test_helper'

class ShoutTest < ActiveRecord::TestCase
  fixtures :shouts

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end

# == Schema Information
#
# Table name: shouts
#
#  id               :integer(4)      not null, primary key
#  company_id       :integer(4)
#  user_id          :integer(4)
#  created_at       :datetime
#  body             :text
#  shout_channel_id :integer(4)
#  message_type     :integer(4)      default(0)
#  nick             :string(255)
#

