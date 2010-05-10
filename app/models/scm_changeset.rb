# commit
# author - author of the commit, string
# user - author of the commit, User (NULL if author not registered in system)
class ScmChangeset < ActiveRecord::Base
  belongs_to :user

  belongs_to :scm_project

  has_many :scm_files, :dependent => :destroy
  has_one  :work_log

  before_create do | changeset |
    if changeset.user_id.nil?
      user= User.find_by_email(changeset.author)
      user= User.find_by_username(changeset.author) if user.nil?
      user= User.find_by_name(changeset.author) if user.nil?
      changeset.user=user
    end
  end

  after_create do | changeset |
    num= changeset.message.scan(/#(\d+)/).first
    unless (num.nil? or num.first.blank?)
      num = num.first
      task= changeset.scm_project.project.tasks.find_by_task_num(num)
      unless task.nil?
        log= WorkLog.create
        log.scm_changeset=changeset
        log.task= task
        log.project= task.project
        log.started_at=Time.now
        log.body = changeset.message
        log.log_type=EventLog::SCM_COMMIT
        log.user = changeset.user.nil? ? User.first : changeset.user
        log.save!
        log.send_notifications
        log.save!
      end
    end
  end


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
  def ScmChangeset.github_parser(payload)
    payload = JSON.parse(payload)
    payload['commits'].collect do |commit|
      changeset= { }
      changeset[:changeset_rev]= commit['id']
      changeset[:files]=[]
      changeset[:files] << commit['modified'].collect{ |file| { :path=>file, :state=>:modified } } unless commit['modified'].nil?
      changeset[:files] << commit['added'].collect{ |file| { :path=>file, :state=>:added } }       unless commit['added'].nil?
      changeset[:files] << commit['deleted'].collect{ |file| { :path=>file, :state=>:deleted } }   unless commit['deleted'].nil?
      changeset[:files].flatten!
      changeset[:author] = commit['author']['name']
      changeset[:message] = commit['message']
      changeset[:commit_date] = commit['timestamp']
      changeset
    end
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

