FactoryGirl.define do
  factory :company do
    sequence(:name) { |n| "Company#{n}" }
    sequence(:subdomain) { |n| "Subdomain#{n}" }
  end
end
