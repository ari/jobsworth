class ScmFile < ActiveRecord::Base
  has_many :scm_revisions, :dependent => :destroy
  belongs_to :project
  belongs_to :company
end
