require 'spec_helper'

describe TaskFiltersController do  
  WORD_LIST = ["tomorrow","today","yesterday","in the past","in the future",
               "last week","last month","last year","today or later",
               "today or earlier","tomorrow or earlier", "tomorrow or later",
               "yesterday or earlier", "yesterday or later"]
  render_views

  describe "search" do
    before :each do
      sign_in_normal_user
      TimeRange.create_defaults
    end
  
    it "should return all matches for time range key words" do
      WORD_LIST.each do |word|
        xhr :get, :search, :term => word
        response.should be_success
        JSON(response.body).each do |r|
          r.each do |key, value|
            value.downcase.should include(word.downcase) if key == "value"
          end
        end
      end
    end
  end

  describe "update filter" do
    before :each do
      sign_in_normal_user
      TimeRange.create_defaults
    end
   
    it "should successfully update the task filter" do
      WORD_LIST.each do |word|
        id = TimeRange.where(:name => word).first.id
        xhr :post, :update_current_filter, {:filter => word, :redirect_action => "/tasks/list",
                                            :task_filter => { :unread_only => "false", :qualifiers_attributes => 
                                            [{:qualifiable_id => id, :qualifiable_type => "TimeRange", 
                                            :qualifiable_column => "due_at", :reversed => "false"}]}}
        response.should be_success
        TaskFilter.last.name.downcase.should include word.downcase
      end
    end
    
    it "should render the right template for 'xhr' request" do
      WORD_LIST.each do |word|
        id = TimeRange.where(:name => word).first.id
        xhr :post, :update_current_filter, {:filter => word, :redirect_action => "/tasks/list",
                                            :task_filter => { :unread_only => "false", :qualifiers_attributes => 
                                            [{:qualifiable_id => id, :qualifiable_type => "TimeRange", 
                                            :qualifiable_column => "due_at", :reversed => "false"}]}}
        response.should render_template 'task_filters/_search_filter_keys'
      end
    end
    
    it "should redirect to '/tasks/list' if an 'http' request" do
      WORD_LIST.each do |word|
        id = TimeRange.where(:name => word).first.id
        post :update_current_filter, { :filter => word, :redirect_action => "/tasks/list", 
                                       :task_filter => { :unread_only => "false", :qualifiers_attributes => 
                                       [{ :qualifiable_id => id, :qualifiable_type => "TimeRange", 
                                       :qualifiable_column => "due_at", :reversed => "false"}]}}
        should redirect_to '/tasks/list'
      end
    end

  end    
end
