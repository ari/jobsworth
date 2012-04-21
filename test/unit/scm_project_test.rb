require "test_helper"

class ScmProjectTest < ActiveRecord::TestCase
  fixtures :scm_projects

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end






# == Schema Information
#
# Table name: scm_projects
#
#  id               :integer(4)      not null, primary key
#  project_id       :integer(4)
#  company_id       :integer(4)
#  scm_type         :string(255)
#  last_commit_date :datetime
#  last_update      :datetime
#  last_checkout    :datetime
#  module           :text
#  location         :text
#  secret_key       :string(255)
#
# Indexes
#
#  fk_scm_projects_company_id  (company_id)
#

