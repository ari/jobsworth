require 'spec_helper'

describe ScmProjectsHelper do

  #Delete this example and add some real ones or delete this file
  it "should be included in the object returned by #helper" do
    included_modules = (class << helper; self; end).send :included_modules
    expect(included_modules).to include(ScmProjectsHelper)
  end

end
