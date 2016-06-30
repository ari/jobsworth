FactoryGirl.define do
  factory :preference, class: 'Preference' do
    preferencable_type 'Company'
  end
end
