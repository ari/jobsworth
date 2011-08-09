require "test_helper"

class TaskTemplatesControllerTest < ActionController::TestCase
  fixtures :users, :companies, :tasks, :customers, :projects
 signed_in_admin_context do
    setup do
      @request.with_subdomain('cit')
      @customer= customers(:internal_customer)
    end
    should "get list page" do
      get :index
      assert_response :success
    end
    should "get new template page" do
      get :new
      assert_response :success
    end
    should "get edit template page" do
      get :edit, :id => 1
      assert_response :success
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
          :notify=>@user.company.user_ids,
          :todos=> [{"name"=>"First Todo", "completed_at"=>"", "creator_id"=>@user.id, "completed_by_user_id"=>""},
                    {"name"=>"Second Todo", "completed_at"=>"", "creator_id"=>@user.id, "completed_by_user_id"=>""}]
        }
        post(:create, @parameters.deep_clone)
        @template=Template.find_by_name(@parameters[:task][:name])
      end
      should 'create task template with given parameters' do
        assert_not_nil @template
        assert_equal @parameters[:task][:description], @template.description
        assert_equal @parameters[:task][:project_id], @template.project.id
        assert_equal @parameters[:users].first, @template.users.first.id
      end
      should 'create todos' do
        assert_same_elements ["First Todo", "Second Todo"], @template.todos.collect(&:name)
      end
      should 'not create any worklogs' do
        assert_not_nil @template
        assert_equal 0, WorkLog.where(:task_id=>@template.id).all.size
      end
    end
    context 'when update task tamplate' do
      setup do
        @template = Template.first
        @template.users.clear
        @parameters={ :id=>@template.id,
          :task=>{
            :id=>@template.id,
            :name=>@template.name + '!!update!!',
            :description=> @template.description+'!!update!!',
            :properties=>{ },
            :customer_attributes=>{ }
          },
          :users=> @user.company.user_ids,
          :assigned=> [@user.id],
          :notify=> @user.company.user_ids
        }
        @user.company.properties.each{|p| @parameters[:task][:properties][p.id]=p.property_values.last.id }
        @user.company.customers.each{|c| @parameters[:task][:customer_attributes][c.id]=c.id}
        post(:update, @parameters.deep_clone)
        @template.reload
      end
      should 'change attributes' do
        assert_equal @parameters[:task][:name], @template.name
        assert_equal @parameters[:task][:description], @template.description
      end
      should 'change custom property values' do
        assert_not_equal 0, @user.company.properties.size
        @user.company.properties.each do |p|
          assert_not_nil @template.property_value(p)
          assert_equal @parameters[:task][:properties][p.id], @template.property_value(p).id
        end
      end
      should 'change todos' do
      end
      should 'change users' do
        assert_same_elements @parameters[:users], @template.user_ids
        assert_equal @parameters[:assigned], @template.owner_ids
      end
      should 'change clients' do
        assert_equal @parameters[:task][:customer_attributes].keys, @template.customer_ids
      end
      should 'not add any dependecies' do
        assert_equal 0, @template.dependencies.size
      end
      should 'not add any worklogs' do
        assert_equal 0, WorkLog.where(:task_id=>@template.id).all.size
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
