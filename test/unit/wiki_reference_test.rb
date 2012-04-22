require "test_helper"

class WikiReferenceTest < ActiveRecord::TestCase
  fixtures :wiki_references

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end






# == Schema Information
#
# Table name: wiki_references
#
#  id              :integer(4)      not null, primary key
#  wiki_page_id    :integer(4)
#  referenced_name :string(255)
#  created_at      :datetime
#  updated_at      :datetime
#
# Indexes
#
#  index_wiki_references_on_wiki_page_id  (wiki_page_id)
#

