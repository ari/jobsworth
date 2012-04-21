require "test_helper"

class KeywordTest < ActiveSupport::TestCase
  should belong_to(:task_filter)
  should belong_to(:company)

  should validate_presence_of(:task_filter)
  should validate_presence_of(:company)
end






# == Schema Information
#
# Table name: keywords
#
#  id             :integer(4)      not null, primary key
#  company_id     :integer(4)
#  task_filter_id :integer(4)
#  word           :string(255)
#  created_at     :datetime
#  updated_at     :datetime
#  reversed       :boolean(1)      default(FALSE)
#
# Indexes
#
#  fk_keywords_task_filter_id  (task_filter_id)
#

