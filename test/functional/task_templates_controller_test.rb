require 'test_helper'

class TaskTemplatesControllerTest < ActionController::TestCase
  fixtures :users, :companies, :tasks, :customers, :projects
  context 'a logged in user' do
    def setup
      @request.with_subdomain('cit')
      @user = users(:admin)
      @request.session[:user_id] = @user.id
      @user.company.create_default_statuses
      @customer= customers(:internal_customer)
    end
    context 'when create new task template' do
      setup do
        @parameters= {
          :task=>{
            :name=>'Task template',
            :description=>'Just a test task template',
            :due_at=>'2/2/2010',
            :status => 0,
            :project_id=>projects(:test_project).id,
            :customer_attributes=>{@customer.id=>"1"},
            :notify_emails=>'some@email.com'
          },
          :users=> @user.company.user_ids,
          :assigned=>@user.company.user_ids,
          :notify=>@user.company.user_ids
        }
        post(:create, @parameters)
        @template=Template.find_by_name(@parameters[:task][:name])
      end
      should 'create task template with given parameters' do
        assert_not_nil @template
        assert_equal @parameters[:task][:description], @template.description
        assert_equal @parameters[:task][:project_id], @template.project.id
        assert_equal @parameters[:users].first, @template.users.first.id
      end
      should 'not create any worklogs' do
        assert_not_nil @template
        assert_equal 0, @template.work_logs.size
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
