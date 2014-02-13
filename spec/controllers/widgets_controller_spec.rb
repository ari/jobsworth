require 'spec_helper'

describe WidgetsController do  
  
  render_views

  describe "Task Widget" do
    before :each do
      sign_in_admin
    end

    it "should show the tasks in descending order" do
      tasks = FactoryGirl.create_list(:task, 10)
      tasks.each do |task|
        FactoryGirl.create(:work_log, :task_id => task.id)
        if ProjectPermission.where(:project_id => task.project_id).size == 0
          FactoryGirl.create(:project_permission, :company_id => @logged_user.company_id, :user_id => @logged_user.id, :project_id => task.project_id)
        end
      end
      widget = FactoryGirl.create(:widget,
                                  :user => @logged_user,
                                  :company => @logged_user.company,
                                  :configured => true,
                                  :mine => false,
                                  :name =>  "Recent tasks widget",
                                  :number => 5,
                                  :widget_type =>0,
                                  :column => 0,
                                  :position => 0,
                                  :order_by => "date")
      get :show, :id => widget.id
      expect(assigns(:items)).to eq assigns(:items).sort_by(&:created_at)
    end
  end    
end
