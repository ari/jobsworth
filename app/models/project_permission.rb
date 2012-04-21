# encoding: UTF-8
# Permissions for a User on a Project

class ProjectPermission < ActiveRecord::Base
  belongs_to :company
  belongs_to :project
  belongs_to :user
  def self.permissions
     ['comment', 'work', 'close', 'see_unwatched', 'create', 'edit', 'reassign', 'milestone', 'report', 'grant', 'all']
  end
  def self.message_for(permission)
    message = {'read'=> "You may not view this task.",
               'comment'=> "You may not add a comment to tasks in this project.",
               'work'=> "You may not add worklogs to tasks in this project.",
               'close'=> "You may not change the resolution of tasks in this project.",
               'see_unwatched'=> "You may not view this task.",
               'create'=> "You may not create tasks in this project.",
               'edit' => "You may not edit tasks in this project.",
               'reassign'=> "You may not assign users to tasks in this project.",
               'milestone'=> "You may not change the milestone of tasks in this project.",
               'report'=> "You may not see reports for this project.",
               'grant' => "You may not assign access rights for users in this project."
              }[permission]
    raise "Can not find message for permission: #{permission}" if message.nil?
    return message
  end
  def can? (perm)
    case perm
    when 'comment'    then self.can_comment?
    when 'work'       then self.can_work?
    when 'close'      then self.can_close?
    when 'report'     then self.can_report?
    when 'create'     then self.can_create?
    when 'edit'       then self.can_edit?
    when 'reassign'   then self.can_reassign?
    when 'milestone'  then self.can_milestone?
    when 'grant'      then self.can_grant?
    when 'see_unwatched' then self.can_see_unwatched?
    when 'all'        then (self.can_comment? && self.can_work? && self.can_close? && self.can_report? && self.can_create? && self.can_edit? &&
            self.can_reassign? && self.can_milestone? && self.can_grant? && self.can_see_unwatched?)
    end
  end

  def set(perm)
    case perm
    when 'comment'    then self.can_comment = 1
    when 'work'       then self.can_work = 1
    when 'close'      then self.can_close = 1
    when 'report'     then self.can_report = 1
    when 'create'     then self.can_create = 1
    when 'edit'       then self.can_edit = 1
    when 'reassign'   then self.can_reassign = 1
    when 'milestone'  then self.can_milestone = 1
    when 'grant'      then self.can_grant = 1
    when 'see_unwatched' then self.can_see_unwatched=true
    when 'all'        then
      self.can_comment = 1
      self.can_work = 1
      self.can_close = 1
      self.can_report = 1
      self.can_create = 1
      self.can_edit = 1
      self.can_reassign = 1
      self.can_milestone = 1
      self.can_grant = 1
      self.can_see_unwatched=true
    end
  end

  def remove(perm)
    case perm
    when 'comment'    then self.can_comment = 0
    when 'work'       then self.can_work = 0
    when 'close'      then self.can_close = 0
    when 'report'     then self.can_report = 0
    when 'create'     then self.can_create = 0
    when 'edit'       then self.can_edit = 0
    when 'reassign'   then self.can_reassign = 0
    when 'milestone'  then self.can_milestone = 0
    when 'grant'      then self.can_grant = 0
    when 'see_unwatched' then self.can_see_unwatched=false
    when 'all'        then
      self.can_comment = 0
      self.can_work = 0
      self.can_close = 0
      self.can_report = 0
      self.can_create = 0
      self.can_edit = 0
      self.can_reassign = 0
      self.can_milestone = 0
      self.can_grant = 0
      self.can_see_unwatched=false
    end
  end


end








# == Schema Information
#
# Table name: project_permissions
#
#  id                :integer(4)      not null, primary key
#  company_id        :integer(4)
#  project_id        :integer(4)
#  user_id           :integer(4)
#  created_at        :datetime
#  can_comment       :boolean(1)      default(FALSE)
#  can_work          :boolean(1)      default(FALSE)
#  can_report        :boolean(1)      default(FALSE)
#  can_create        :boolean(1)      default(FALSE)
#  can_edit          :boolean(1)      default(FALSE)
#  can_reassign      :boolean(1)      default(FALSE)
#  can_close         :boolean(1)      default(FALSE)
#  can_grant         :boolean(1)      default(FALSE)
#  can_milestone     :boolean(1)      default(FALSE)
#  can_see_unwatched :boolean(1)      default(TRUE)
#
# Indexes
#
#  fk_project_permissions_company_id     (company_id)
#  project_permissions_project_id_index  (project_id)
#  project_permissions_user_id_index     (user_id)
#

