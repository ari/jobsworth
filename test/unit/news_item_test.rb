require "test_helper"

class NewsItemTest < ActiveRecord::TestCase
  fixtures :news_items

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end

# == Schema Information
#
# Table name: news_items
#
#  id         :integer(4)      not null, primary key
#  created_at :datetime
#  body       :text
#  portal     :boolean(1)      default(TRUE)
#

