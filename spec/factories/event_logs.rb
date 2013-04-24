FactoryGirl.define do
  factory :event_log do
    association :company
    association(:project) { FactoryGirl.create :project, company: company }
    association(:user)    { FactoryGirl.create :user,    company: company, projects: [project] }

    event_type { rand(8) }
  end
end

