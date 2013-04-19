FactoryGirl.define do
  factory :abstract_task do
    description { Faker::Lorem.paragraph }
    association :company, :factory => :company
    association :project, :factory => :project

    weight_adjustment 0
    sequence(:name) { |n| "#{type} #{n}" }

    trait(:with_customers) do
      ignore { customer_count 1 }
      customers { FactoryGirl.create_list :customer, customer_count }
    end

    factory :task_record, aliases: [:task], class: 'TaskRecord' do
      factory :task_with_customers, traits: [:with_customers]
    end

    factory :template, class: 'Template'
  end
end
