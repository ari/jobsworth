# encoding: UTF-8
# commit
# author - author of the commit, string
# user - author of the commit, User (NULL if author not registered in system)
class ScmChangeset < ActiveRecord::Base
  belongs_to :user
  belongs_to :scm_project
  belongs_to :task, :touch =>true

  has_many :scm_files, :dependent => :destroy

  validates_presence_of :scm_project
  validates_presence_of :author

  accepts_nested_attributes_for :scm_files
  before_create do | changeset |
    if changeset.user_id.nil?
      user= User.by_email(changeset.author).first
      user= User.find_by_username(changeset.author) if user.nil?
      user= User.find_by_name(changeset.author) if user.nil?
      changeset.user=user
    end
    num= changeset.message.scan(/#(\d+)/).first
    unless (num.nil? or num.first.blank?)
      changeset.task= changeset.scm_project.company.tasks.find_by_task_num(num.first)
    end
  end

  def issue_num
    name = "[#{self.changeset_rev}]"
  end

  def name
    n = "#{self.scm_project.scm_type.upcase} Commit"
    if self.scm_project.scm_type == 'svn'
      n << " (r#{self.changeset_rev})"
    end

    if self.scm_files && self.scm_files.size > 0
      n << " [#{self.scm_files.size} #{self.scm_files.size == 1 ? 'file' : 'files'}]"
    end

    n
  end

  def full_name
    "#{self.scm_project.location}"
  end

  def ScmChangeset.github_parser(payload)
    payload = JSON.parse(payload)
    payload['commits'].collect do |commit|
      changeset= { }
      changeset[:changeset_rev]= commit['id']
      changeset[:scm_files_attributes]=[]
      changeset[:scm_files_attributes] << commit['modified'].collect{ |file| { :path=>file, :state=>'M' } } unless commit['modified'].nil?
      changeset[:scm_files_attributes] << commit['added'].collect{ |file| { :path=>file, :state=>'A' } }       unless commit['added'].nil?
      changeset[:scm_files_attributes] << commit['deleted'].collect{ |file| { :path=>file, :state=>'D' } }   unless commit['deleted'].nil?
      changeset[:scm_files_attributes].flatten!
      changeset[:author] = commit['author']['name']
      changeset[:message] = commit['message']
      changeset[:commit_date] = commit['timestamp']
      changeset
    end
  end

  def ScmChangeset.google_parser(payload)
    payload = JSON.parse(payload)
    payload['revisions'].collect do |commit|
      changeset= { }
      changeset[:changeset_rev]= commit['revision']
      changeset[:scm_files_attributes]=[]
      changeset[:scm_files_attributes] << commit['modified'].collect{ |file| { :path=>file, :state=>'M' } } unless commit['modified'].nil?
      changeset[:scm_files_attributes] << commit['added'].collect{ |file| { :path=>file, :state=>'A' } }       unless commit['added'].nil?
      changeset[:scm_files_attributes] << commit['removed'].collect{ |file| { :path=>file, :state=>'D' } }   unless commit['removed'].nil?
      changeset[:scm_files_attributes].flatten!
      changeset[:author] = commit['author']
      changeset[:message] = commit['message']
      changeset[:commit_date] = Time.at(commit['timestamp'])
      changeset
    end
  end
  def ScmChangeset.create_from_web_hook(params)
    scm_project = ScmProject.find_by_secret_key(params[:secret_key])
    if scm_project.nil?
      return false
    end
    case params[:provider]
      when 'github' then github_parser(params[:payload])
      when 'google', 'json' then google_parser(params[:payload])
      else return false
    end.collect do |changeset|
      scm_changeset=ScmChangeset.find_or_create_by_scm_project_id_and_changeset_rev(scm_project.id, changeset[:changeset_rev])
      scm_changeset.attributes=changeset
      return false unless scm_changeset.save
      scm_changeset
    end
  end

  def ScmChangeset.for_list(params)
    conditions={ }
    unless params[:scm_project_id].blank?
      conditions[:scm_project_id]= params[:scm_project_id]
    end
    unless params[:task_id].blank?
      conditions[:task_id]=params[:task_id]
    end
    return nil if conditions.empty?
    ScmChangeset.where(conditions)
  end
end







# == Schema Information
#
# Table name: scm_changesets
#
#  id              :integer(4)      not null, primary key
#  user_id         :integer(4)
#  scm_project_id  :integer(4)
#  author          :string(255)
#  changeset_num   :integer(4)
#  commit_date     :datetime
#  changeset_rev   :string(255)
#  message         :text
#  scm_files_count :integer(4)
#  task_id         :integer(4)
#
# Indexes
#
#  scm_changesets_author_index       (author)
#  scm_changesets_commit_date_index  (commit_date)
#  fk_scm_changesets_user_id         (user_id)
#

