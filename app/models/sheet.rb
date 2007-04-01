class Sheet < ActiveRecord::Base
  belongs_to :task
  belongs_to :project
  belongs_to :user

end
