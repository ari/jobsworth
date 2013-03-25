FactoryGirl.define do
  factory :company do
    sequence(:name) { |n| "Company#{n}" }
    sequence(:subdomain) { |n| "Subdomain#{n}" }

  trait(:no_billing)  { use_billing false }
  factory :company_with_no_billing, :traits => [:no_billing]

  end
end
