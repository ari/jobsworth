class ScmRevision < ActiveRecord::Base
  belongs_to :company
  belongs_to :project
  belongs_to :user
  belongs_to :scm_changeset
  belongs_to :scm_file
end
