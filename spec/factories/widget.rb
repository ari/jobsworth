FactoryGirl.define do
  factory :widget, class: 'Widget' do
    association :user, :factory => :user
    association :company, :factory => :company
    
    sequence(:name) { |n| "Widget #{n}" }
    configured false
    mine true
    number 5
    column 0
    position 0    
  end
end
