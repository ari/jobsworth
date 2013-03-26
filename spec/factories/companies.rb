FactoryGirl.define do
  factory :company do
    sequence(:name) { |n| "Company#{n}" }
    sequence(:subdomain) { |n| "Subdomain#{n}" }

    trait(:no_billing)  { use_billing false }
    trait(:no_score_rules)  { use_score_rules false }
    factory :company_with_no_billing, :traits => [:no_billing]
    factory :company_with_no_score_rules, :traits => [:no_score_rules]
  end
end
