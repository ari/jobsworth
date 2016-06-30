require 'spec_helper'

describe EmailsController do

  describe 'create' do
    before :each do
      sign_in_normal_user
      Setting.domain = 'example.com' # use the same domain in squish_mail.msg
    end

    it 'should attach a new task to a default projet' do
      company = FactoryGirl.create(:company, :subdomain => Setting.domain.split('.')[0])
      @logged_user.company = company
      @logged_user.save!
      project = FactoryGirl.create(:project, :company => @logged_user.company)
      FactoryGirl.create(:customer, :company => @logged_user.company)
      FactoryGirl.create(:preference,
                         :preferencable_id => @logged_user.company.id,
                         :preferencable_type => 'Company',
                         :key => 'incoming_email_project',
                         :value => project.id)

      total = TaskRecord.count
      post :create, :secret => Setting.receiving_emails.secret,
           :email => ERB.new(File.read('spec/squish_mail.msg.erb')).result
      expect(response.body).to eq({:success => true}.to_json)
      expect(TaskRecord.count).to eq(total + 1)
      expect(TaskRecord.last.customers.size).not_to eq(0)
      expect(TaskRecord.last.project_id).to eq(project.id)
    end
  end
end
