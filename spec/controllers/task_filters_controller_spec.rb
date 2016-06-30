require 'spec_helper'

describe TaskFiltersController do
  # Add the task filters to be tested in this list.
  WORD_LIST = ['Tomorrow', 'Today', 'Yesterday', 'In the past', 'In the future',
               'Last week', 'Last month', 'Last year', 'Today or later',
               'Today or earlier', 'Tomorrow or earlier', 'Tomorrow or later',
               'Yesterday or earlier', 'Yesterday or later']
  render_views

  describe 'search' do
    before :each do
      sign_in_normal_user
      TimeRange.create_defaults
    end

    it 'should return all matches for time range key words' do
      WORD_LIST.each do |word|
        xhr :get, :search, :term => word
        expect(response).to be_success
        JSON(response.body).each do |r|
          r.each do |key, value|
            expect(value.downcase).to include(word.downcase) if key == 'value'
          end
        end
      end
    end
  end

  describe 'update filter' do
    before :each do
      sign_in_normal_user
      TimeRange.create_defaults
    end

    it 'should successfully update the task filter' do
      WORD_LIST.each do |word|
        id = TimeRange.where(:name => word).first.id
        xhr :post, :update_current_filter, {:filter => word, :redirect_action => '/tasks/list',
                                            :task_filter => {:unread_only => 'false', :qualifiers_attributes =>
                                                [{:qualifiable_id => id, :qualifiable_type => 'TimeRange',
                                                  :qualifiable_column => 'due_at', :reversed => 'false'}]}}
        expect(response).to be_success
        expect(TaskFilter.last.name.downcase).to include word.downcase
      end
    end

    it "should render the right template for 'xhr' request" do
      WORD_LIST.each do |word|
        id = TimeRange.where(:name => word).first.id
        xhr :post, :update_current_filter, {:filter => word, :redirect_action => '/tasks/list',
                                            :task_filter => {:unread_only => 'false', :qualifiers_attributes =>
                                                [{:qualifiable_id => id, :qualifiable_type => 'TimeRange',
                                                  :qualifiable_column => 'due_at', :reversed => 'false'}]}}
        expect(response).to render_template 'task_filters/_search_filter_keys'
      end
    end

    it "should redirect to '/tasks/list' if an 'http' request" do
      WORD_LIST.each do |word|
        id = TimeRange.where(:name => word).first.id
        post :update_current_filter, {:filter => word, :redirect_action => '/tasks/list',
                                      :task_filter => {:unread_only => 'false', :qualifiers_attributes =>
                                          [{:qualifiable_id => id, :qualifiable_type => 'TimeRange',
                                            :qualifiable_column => 'due_at', :reversed => 'false'}]}}
        is_expected.to redirect_to '/tasks/list'
      end
    end

  end
end
