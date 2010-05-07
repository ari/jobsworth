# commit
# author - author of the commit, string
# user - author of the commit, User (NULL if author not registered in system)
class ScmChangeset < ActiveRecord::Base
  belongs_to :user

  belongs_to :scm_project

  has_many :scm_files, :dependent => :destroy
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


# == Schema Information
#
# Table name: scm_changesets
#
#  id             :integer(4)      not null, primary key
#  user_id        :integer(4)
#  scm_project_id :integer(4)
#  author         :string(255)
#  changeset_num  :integer(4)
#  commit_date    :datetime
#  changeset_rev  :string(255)
#  message        :text
#
# Indexes
#
#  scm_changesets_commit_date_index  (commit_date)
#  scm_changesets_author_index       (author)
#  fk_scm_changesets_user_id         (user_id)

