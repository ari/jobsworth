class ProjectFolder < ActiveRecord::Base
  acts_as_nested_set :scope => "project_id = #{project_id}"

  belongs_to :project
  has_many   :project_files

end
