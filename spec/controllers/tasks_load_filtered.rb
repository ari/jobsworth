require 'spec_helper'

describe TasksController do
  WORD_LIST = ["tomorrow","today","yesterday","in the past","in the future",
               "last week","last month","last year","today or later",
               "today or earlier","tomorrow or earlier", "tomorrow or later",
               "yesterday or earlier", "yesterday or later"]
    
  before :each do
    sign_in_normal_user
    TimeRange.create_defaults
  end
  
  it "Should load tasks successfully for each filter" do
    WORD_LIST.each do |word|
        id = TimeRange.where(:name => word).first.id
        FactoryGirl.build(:task_filter,:name=>word,:created_at=>Time.now)
        get :index, :format => "json"        
        expect(response).to render_template("tasks/index")
    end
  end
end

def signin_normal (user)
  login_path = "/auth/users/sign_in"
  post login_path, {"user"=>{"subdomain"=>"jobsworth", "username"=>user.username, "password"=>user.password, "remember_me"=>"0"}, "commit"=>"Login"}
end
