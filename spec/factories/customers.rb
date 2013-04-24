FactoryGirl.define do
  factory :customer do
    association :company
    sequence(:name) { |n| "Customer #{n}" }
  end
end
