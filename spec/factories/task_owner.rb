FactoryGirl.define do
  factory :task_owner, class: 'TaskOwner' do
    association :task, :factory => :task
  end
end
