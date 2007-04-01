require File.dirname(__FILE__) + '/../test_helper'
require 'projects_controller'

# Re-raise errors caught by the controller.
class ProjectsController; def rescue_action(e) raise e end; end

class ProjectsControllerTest < Test::Unit::TestCase
  fixtures :projects

  def setup
    @controller = ProjectsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_index
    get :index
    assert_rendered_file 'list'
  end

  def test_list
    get :list
    assert_rendered_file 'list'
    assert_template_has 'projects'
  end

  def test_show
    get :show, 'id' => 1
    assert_rendered_file 'show'
    assert_template_has 'project'
    assert_valid_record 'project'
  end

  def test_new
    get :new
    assert_rendered_file 'new'
    assert_template_has 'project'
  end

  def test_create
    num_projects = Project.find_all.size

    post :create, 'project' => { }
    assert_redirected_to :action => 'list'

    assert_equal num_projects + 1, Project.find_all.size
  end

  def test_edit
    get :edit, 'id' => 1
    assert_rendered_file 'edit'
    assert_template_has 'project'
    assert_valid_record 'project'
  end

  def test_update
    post :update, 'id' => 1
    assert_redirected_to :action => 'show', :id => 1
  end

  def test_destroy
    assert_not_nil Project.find(1)

    post :destroy, 'id' => 1
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      project = Project.find(1)
    }
  end
end
