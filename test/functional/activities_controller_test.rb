context "Activities" do 
  fixtures :users, :companies, :customers, :tasks, :projects, :milestones, :work_logs
  
  setup do
    use_controller ActivitiesController

    @request.host = 'cit.local.host'
    @request.session[:user_id] = 1
  end
  
  specify "/index should render :success" do
    get :index
    assigns(:tz).should.equal Timezone.get('Europe/Oslo')
    assigns(:current_user).should.equal User.find(1)
    status.should.be :success
  end

  specify "/list should render :success" do 
    get :list
    status.should.be :success
    template.should.be 'activities/list'
    
    assigns(:projects).should.not.be.nil
    assigns(:projects).size.should.be > 0
    
    assigns(:tasks).should.not.be.nil
    assigns(:tasks).size.should.be > 0
    
    assigns(:tasks).should.not.equal assigns(:new_tasks)
    
  end
  
end
