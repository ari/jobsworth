FactoryGirl.define do
  factory :milestone do
    association :user, :factory => :user
    company { user.company }
    project { FactoryGirl.create(:project, :company => company) }
    sequence(:name) { |n| "Milestone #{n}" }
  end
end
