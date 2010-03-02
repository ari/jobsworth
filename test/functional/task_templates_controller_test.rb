require 'test_helper'

class TaskTemplatesControllerTest < ActionController::TestCase
  fixtures :users, :companies, :task_templates, :customers, :projects
  context 'a logged in user' do
    def setup
      @request.with_subdomain('cit')
      @user = users(:admin)
      @request.session[:user_id] = @user.id
      @user.company.create_default_statuses
    end
    context 'when create new task template' do
      setup do
        @parameters= { :task=>{ :name=>'Task template', :description=>'Just a test task template', :due_at=>'2/2/2010', :project_id=>1, :customer_attributes=>{:"1"=>"1"}, :users=>["1"], :assigned=>["1"], :notify=>["1"], :notify_emails=>'some@email.com', :set_custom_attribute_values=>[{ :custom_attribute_id=>'1', :choice_id=>'1'}] }}
        post(:create, @parameters)
        @template=Templates.find_by_name(@parameters[:task][:name])
      end
      should 'create task template with given parameters' do
        assert_not_nil @template
        assert_equal @paremeters[:task][:description], @template.description
        assert_equal @parameters[:task][:project_id], @template.project.id
        assert_equal @parameters[:task][:users], @template.users.first.id
      end
      should 'not create any worklogs' do
        assert_not_nil @template
        assert_zero @template.work_logs.size
      end
    end
    context 'when update task tamplate' do
      should 'change attributes' do
      end
      should 'change custom property values' do
      end
      should 'add todo' do
      end
      should 'remove todo' do
      end
      should 'add users' do
      end
      should 'remove users' do
      end
      should 'add client' do
      end
      should 'remove client' do
      end
      should 'can not add any dependecies' do
      end
      should 'can not add any worklogs' do
      end
    end
    context 'when create task from given template' do
      context ', a created tasks' do
        should 'copy all attributes from tamplate' do
        end
        should 'copy all todos from template' do
        end
        should 'assing all users from template' do
        end
        should 'assing all clients from template' do
        end
        should 'assing all custom property values' do
        end
      end
      context ', the template' do
        should 'not change' do
        end
      end
    end
  end
end
