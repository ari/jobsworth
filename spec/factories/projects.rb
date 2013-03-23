FactoryGirl.define do
  factory :project do
    association :company,   :factory => :company
    association :customer,  :factory => :customer
    sequence(:name) { |n| "Project #{n}" }
  end
end
