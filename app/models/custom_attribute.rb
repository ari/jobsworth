class CustomAttribute < ActiveRecord::Base
  validates_presence_of :attributable_type
  validates_presence_of :display_name

end
