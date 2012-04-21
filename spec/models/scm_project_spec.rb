require 'spec_helper'

describe ScmProject do
  before(:each) do
    @scm_project=ScmProject.create(:company=>Company.make)
  end
  it "should generate secret_key(12 characters random string) when created" do
    @scm_project.secret_key.should have(12).characters
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

