# A saved filter which can be applied to a group of tasks

class View < ActiveRecord::Base

  belongs_to :user
  belongs_to :company

end
