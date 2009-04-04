context "CustomAttributes" do
  fixtures :users, :companies
  
  setup do
    use_controller CustomAttributesController

    @request.with_subdomain('cit')
    @request.session[:user_id] = users(:admin).id
  end
  
  specify "/index should render :success" do
    get :index
    status.should.be :success
  end

  specify "/edit should render :success" do
    get :index, :type => "User"
    status.should.be :success
  end

end
