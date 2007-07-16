class ProjectFolder < ActiveRecord::Base
  acts_as_tree :order => 'created_at'

  belongs_to :project
  has_many   :project_files

end
