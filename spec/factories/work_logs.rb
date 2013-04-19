FactoryGirl.define do
  factory :work_log do
    association :company
    association(:customer)  { FactoryGirl.create :customer,  company: company }
    association(:project)   { FactoryGirl.create :project,   company: company, customer: customer }
    association(:user)      { FactoryGirl.create :user,      company: company, projects: [project] }
    association(:task)      { FactoryGirl.create :task,      company: company, project: project, users: [user] }
    association(:event_log) { FactoryGirl.create :event_log, company: company, project: project, user: user }

    started_at { Time.now }

    factory :work_log_comment do
      body { Faker::Lorem.paragraph }
    end
  end
end

