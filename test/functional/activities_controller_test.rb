require File.dirname(__FILE__) + '/../test_helper'

context "Activities" do
  fixtures :users, :companies, :customers, :tasks, :projects, :milestones, :work_logs
  
  setup do
    use_controller ActivitiesController

    @request.with_subdomain('cit')
    @request.session[:user_id] = users(:admin).id
  end
  
  specify "/index should render :success" do
    get :index
    assigns(:current_user).tz.should.equal Timezone.get('Europe/Oslo')
    assigns(:current_user).should.equal users(:admin)
    status.should.be :success
  end

  specify "/list should render :success" do
    get :list
    status.should.be :success
    template.should.be 'activities/list'    
  end
  
end
