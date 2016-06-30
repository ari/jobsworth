FactoryGirl.define do
  factory :task_filter do
    sequence(:name) { |n| "Name #{n}" }
    sequence(:created_at) { |n| "Created at #{n}" }
  end
end
