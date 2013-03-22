FactoryGirl.define do
  factory :company do
    sequence(:name) { |n| "Company#{n}" }
    sequence(:subdomain) { |n| "Subdomain#{n}" }

    factory :company_with_admin do
      association :admin, :factory => :admin
    end
  end
end
