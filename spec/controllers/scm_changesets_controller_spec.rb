require 'spec_helper'

describe ScmChangesetsController do

  before(:each) do
    sign_in User.make
  end

  describe "POST 'create'" do
    context "with valid params" do

      before(:each) do
        expect(ScmChangeset).to receive(:create_from_web_hook).
                     with("scm_changeset" =>  { "these" => "params" },
                          "action"        =>  "create",
                          "controller"    =>  "scm_changesets").
                     and_return(mock_model(ScmChangeset))

        post :create, :scm_changeset => { :these=> :params }
      end

      it "respond with HTTP-STATUS: 201 CREATED" do
        expect(response.status).to eq(201)
      end
    end

    context "with invalid params" do
      before(:each) do
        expect(ScmChangeset).
          to receive(:create_from_web_hook).
          with("scm_changeset" => { "these" => "params" },
               "action" => "create",
               "controller" => "scm_changesets").
          and_return(false)

        post :create, :scm_changeset=>{ :these=> "params" }
      end

      it "respond with HTTP-STATUS: 422 Unprocessable Entity" do
        expect(response.status).to eq(422)
      end
    end
  end
  describe "GET list" do
    before(:each) do
      login_user
    end
    context "with valid params" do
      before(:each) do
        expect(ScmChangeset).to receive(:for_list).with( 'these'=> "params" , "action"=>"list", "controller"=>"scm_changesets").and_return([mock_model(ScmChangeset)])
        get :list, 'these'=>'params'
      end
      it "should respond ok" do
        expect(response).to be_success
      end
      it "should render list template" do
        expect(response).to render_template('list')
      end
    end
    context "with invalid params" do
      before(:each) do
        expect(ScmChangeset).to receive(:for_list).with( 'these'=> "params" , "action"=>"list", "controller"=>"scm_changesets").and_return(nil)
        get :list, 'these'=>'params'
      end
      it "should respond ok" do
        expect(response).to be_success
      end
      it "should render empty body" do
        expect(response.body).to be_empty
      end
    end
  end
end
