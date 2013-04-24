FactoryGirl.define do
  factory :property do
    association :company, :factory => :company
    sequence(:name) { |n| "Property #{n}" }
  end
end
