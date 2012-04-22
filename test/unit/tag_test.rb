require "test_helper"

class TagTest < ActiveRecord::TestCase
  fixtures :tags

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end






# == Schema Information
#
# Table name: tags
#
#  id         :integer(4)      not null, primary key
#  company_id :integer(4)
#  name       :string(255)
#
# Indexes
#
#  index_tags_on_company_id_and_name  (company_id,name)
#

