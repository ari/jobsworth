FactoryGirl.define do
  factory :user do
    association :company, :factory => :company
    sequence(:name) { |n| "User #{n}" }
    sequence(:username) { |n| "username#{n}" }
    sequence(:email) { |n| "username#{n}@company.com" }
    password "123456"

    trait(:admin) { admin 1 }
    trait(:no_billing)  { association :company, :factory => :company_with_no_billing }
    trait(:no_score_rules)  { association :company, :factory => :company_with_no_score_rules }

    factory :admin, :traits => [:admin]
    factory :admin_with_no_billing, :traits => [:admin, :no_billing]
    factory :admin_with_no_score_rules, :traits => [:admin, :no_score_rules]
  end
end
