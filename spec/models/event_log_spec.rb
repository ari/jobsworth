require 'spec_helper'

def create_user_with_company
  @company = Company.make
  @user    = User.make(:company=>company)
  @user.projects << @company.projects.make
end

def create_event_logs_for(company, user)
  3.times {
    work_log = WorkLog.make(company: company, project: company.projects.first, access_level_id: 0)
    EventLog.make(company: company, project: company.projects.first, event_type: EventLog::TASK_MODIFIED, target: work_log)
  }

  2.times { EventLog.make(company: company, project: company.projects.first, event_type: EventLog::TASK_CREATED) }
  2.times { EventLog.make(company: company, project: company.projects.first, event_type: EventLog::WIKI_MODIFIED) }

  3.times { ProjectFile.make}
  user.projects.each { |project| ProjectFile.make(project: project, company: company) }
end

describe EventLog do
  describe 'accessed_by(user) named scope' do
    before        { create_user_with_company }
    before(:each) { create_event_logs_for company, user }

    let(:user)    { @user }
    let(:company) { @company }
    let(:logs)    { EventLog.accessed_by user }

    context "user's project permission can_see_unwatched = 0" do
      let(:permission) { user.project_permissions.first }

      it 'should return event logs for work logs accessed by user' do
        permission.update_attribute :can_see_unwatched, 0
        event_logs  = logs.where(:target_type => 'WorkLog')

        work_logs_from_event_logs       = event_logs.collect(&:target)
        work_logs_from_accessed_by_user = WorkLog.accessed_by(user)

        expect(work_logs_from_accessed_by_user).to include *work_logs_from_event_logs
      end
    end

    it "should return event logs for project files from user's projects" do
      logs.collect{ |log| log.target.is_a?(ProjectFile) ? log.target : nil}.compact.each do |project_file|
        expect(user.projects).to include(project_file.project)
        expect(project_file.company).to eq(user.company)
      end
    end

    it "should return event logs for wiki pages from user's company" do
      expect(logs.where(:event_type => EventLog::WIKI_MODIFIED).size).to be > 0
    end

  end

  describe 'event_logs_for_timeline(current_user, params)' do

    before        { create_user_with_company }
    before(:each) { create_event_logs_for company, user }

    let(:user)    { @user }
    let(:company) { @company }
    let(:params) do
      { :filter_project => 0,
        :filter_user    => 0,
        :filter_status  => 0,
        :filter_date    => -1 }
    end

    it 'should return event logs only for current_user.projects or project NULL or project = 0' do
      project = company.projects.make
      search_params = params.merge(:filter_status  => EventLog::WIKI_CREATED,
                                   :filter_project => project.id,
                                   :filter_user    => user.id)
      logs = EventLog.event_logs_for_timeline(user, search_params)

      expect(logs).to be_empty
    end

    it 'should return event logs for given params[:filter_user] user id' do
    end

    it 'should return event logs for given params[:filter_project] project id ' do
    end

    it 'should return event logs for given params[:filter_status]' do
      params.merge!(:filter_status=>EventLog::WIKI_MODIFIED)
      logs = EventLog.event_logs_for_timeline(user, params)
      expect(logs.size).to be > 0
    end

  end
end


# == Schema Information
#
# Table name: event_logs
#
#  id          :integer(4)      not null, primary key
#  company_id  :integer(4)
#  project_id  :integer(4)
#  user_id     :integer(4)
#  event_type  :integer(4)
#  target_type :string(255)
#  target_id   :integer(4)
#  title       :string(255)
#  body        :text
#  created_at  :datetime
#  updated_at  :datetime
#  user        :string(255)
#
# Indexes
#
#  index_event_logs_on_company_id_and_project_id  (company_id,project_id)
#  index_event_logs_on_target_id_and_target_type  (target_id,target_type)
#  fk_event_logs_user_id                          (user_id)
#

