class ScmChangeset < ActiveRecord::Base
  belongs_to :company
  belongs_to :project
  belongs_to :user

  belongs_to :scm_project

  has_many :scm_revisions
  has_one  :work_log

  def issue_num
    name = "[#{self.changeset_num}]"
  end

  def name
    n = "#{self.scm_project.scm_type.upcase} Commit"
    if self.scm_project.scm_type == 'svn'
      n << " (r#{self.changeset_rev})"
    end

    if self.scm_revisions && self.scm_revisions.size > 0
      n << " [#{self.scm_revisions.size} #{self.scm_revisions.size == 1 ? 'file' : 'files'}]"
    end

    n
  end

  def full_name
    "#{self.project.name}"
  end

end
