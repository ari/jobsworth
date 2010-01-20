require File.dirname(__FILE__) + '/../test_helper'

class ShoutChannelTest < ActiveRecord::TestCase
  fixtures :shout_channels

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end

# == Schema Information
#
# Table name: shout_channels
#
#  id          :integer(4)      not null, primary key
#  company_id  :integer(4)
#  project_id  :integer(4)
#  name        :string(255)
#  description :text
#  public      :integer(4)
#

