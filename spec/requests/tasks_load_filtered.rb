require 'spec_helper'

describe "Task Load" do
  WORD_LIST = ["tomorrow","today","yesterday","in the past","in the future",
               "last week","last month","last year","today or later",
               "today or earlier","tomorrow or earlier", "tomorrow or later",
               "yesterday or earlier", "yesterday or later"]
    
  before :each do
    user_params = {:username=>"user1", :name=>"User1", :email=>"user1@company.com",:password=>"password"}
    @logged_user = User.make(user_params)
    user = signin_normal @logged_user
    TimeRange.create_defaults
  end
  
  it "Should load tasks successfully for each filter" do
    WORD_LIST.each do |word|
        id = TimeRange.where(:name => word).first.id
        post "task_filters/update_current_filter", {:filter =>word, :redirect_action =>"/tasks/list", :task_filter =>{:unread_only=>"false", :qualifiers_attributes=>[{:qualifiable_id => id, :qualifiable_type => "TimeRange", :qualifiable_column =>"due_at", :reversed =>"false"}]}}
        get "/tasks", :format => "json"
        puts response.body
        expect(response).to render_template("tasks/index.json")
    end    
  end
end

def signin_normal (user)
  login_path = "/auth/users/sign_in"
  post login_path, {"user"=>{"subdomain"=>"jobsworth", "username"=>user.username, "password"=>user.password, "remember_me"=>"0"}, "commit"=>"Login"}
end
