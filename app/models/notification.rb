# Notify which users on Task changes?
class Notification < ActiveRecord::Base
        belongs_to :user
        belongs_to :task
end
