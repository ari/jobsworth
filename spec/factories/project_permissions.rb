FactoryGirl.define do
  factory :project_permission do
    association :company, :factory => :company
    association :user, :factory => :user
    association :project, :factory => :project

    can_comment true
    can_work true
    can_close true
    can_report true
    can_create true
    can_edit true
    can_reassign true
    can_milestone true
    can_grant true
    can_see_unwatched true
  end
end
