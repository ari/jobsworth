require "test_helper"

class WikiPageTest < ActiveRecord::TestCase
  fixtures :wiki_pages

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end






# == Schema Information
#
# Table name: wiki_pages
#
#  id         :integer(4)      not null, primary key
#  company_id :integer(4)
#  project_id :integer(4)
#  created_at :datetime
#  updated_at :datetime
#  name       :string(255)
#  locked_at  :datetime
#  locked_by  :integer(4)
#
# Indexes
#
#  wiki_pages_company_id_index  (company_id)
#

