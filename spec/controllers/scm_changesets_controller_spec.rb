require 'spec_helper'

describe ScmChangesetsController do

  before(:each) do
    sign_in User.make
  end

  describe "POST 'create'" do
    context "with valid params" do

      before(:each) do
        ScmChangeset.should_receive(:create_from_web_hook).
                     with("scm_changeset" =>  { "these" => "params" },
                          "action"        =>  "create",
                          "controller"    =>  "scm_changesets").
                     and_return(mock_model(ScmChangeset))

        post :create, :scm_changeset => { :these=> :params }
      end

      it "respond with HTTP-STATUS: 201 CREATED" do
        response.status.should == 201
      end
    end

    context "with invalid params" do
      before(:each) do
        ScmChangeset.
          should_receive(:create_from_web_hook).
          with("scm_changeset" => { "these" => "params" },
               "action" => "create",
               "controller" => "scm_changesets").
          and_return(false)

        post :create, :scm_changeset=>{ :these=> "params" }
      end

      it "respond with HTTP-STATUS: 422 Unprocessable Entity" do
        response.status.should == 422
      end
    end
  end
  describe "GET list" do
    before(:each) do
      login_user
    end
    context "with valid params" do
      before(:each) do
        ScmChangeset.should_receive(:for_list).with( 'these'=> "params" , "action"=>"list", "controller"=>"scm_changesets").and_return([mock_model(ScmChangeset)])
        get :list, 'these'=>'params'
      end
      it "should respond ok" do
        response.should be_success
      end
      it "should render list template" do
        response.should render_template('list')
      end
    end
    context "with invalid params" do
      before(:each) do
        ScmChangeset.should_receive(:for_list).with( 'these'=> "params" , "action"=>"list", "controller"=>"scm_changesets").and_return(nil)
        get :list, 'these'=>'params'
      end
      it "should respond ok" do
        response.should be_success
      end
      it "should render empty body" do
        response.body.should be_empty
      end
    end
  end
end
