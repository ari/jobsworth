FactoryGirl.define do
  factory :todo do
    task
    association :completed_by_user, factory: :user

    sequence(:name) { |n| "Todo #{n}" }
    sequence :position

    trait(:done)   { completed_at 5.days.ago }
    trait(:undone) { completed_at nil }

    factory :done_todo, traits: [:done]
    factory :undone_todo, traits: [:undone]
  end
end
