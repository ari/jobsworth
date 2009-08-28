class ScmProject < ActiveRecord::Base
  belongs_to :project
  belongs_to :company
  has_many :scm_changesets

end
