require 'spec_helper'

describe ScmProject do
  before(:each) do
    @scm_project=ScmProject.create(:project=>Project.make)
  end

  it "should set company from project if not presented" do
    @scm_project.company.should == @scm_project.project.company
  end
  it "should generate secret_key(12 characters random string) when created" do
    @scm_project.secret_key.should have(12).characters
  end
end
