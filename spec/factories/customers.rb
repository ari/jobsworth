FactoryGirl.define do
  factory :customer do
    association :company, :factory => :company
    sequence(:name) { |n| "Customer #{n}" }
  end
end
