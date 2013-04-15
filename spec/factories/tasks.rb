FactoryGirl.define do
  factory :abstract_task do
    description {Faker::Lorem.paragraph }
    association :company, :factory => :company
    association :project, :factory => :project
    weight_adjustment 0
    type 'AbstractTask'
    sequence(:name) { |n| "#{type} #{n}" }

    factory :task_record, aliases: [:task] do
      type 'TaskRecord'
    end

    factory :template do
      type 'Template'
    end
  end
end
