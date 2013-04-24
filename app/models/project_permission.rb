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
    message = {'read'=> I18n.t("project_permissions.read"),
               'comment'=> I18n.t("project_permissions.comment"),
               'work'=> I18n.t("project_permissions.work"),
               'close'=> I18n.t("project_permissions.close"),
               'see_unwatched'=> I18n.t("project_permissions.see_unwatched"),
               'create'=> I18n.t("project_permissions.create"),
               'edit' => I18n.t("project_permissions.edit"),
               'reassign'=> I18n.t("project_permissions.reassign"),
               'milestone'=> I18n.t("project_permissions.milestone"),
               'report'=> I18n.t("project_permissions.report"),
               'grant' => I18n.t("project_permissions.grant")
              }[permission]
    raise I18n.t("project_permissions.no_message", permission: permission) if message.nil?
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
    when 'comment'    then self.can_comment = false
    when 'work'       then self.can_work = false
    when 'close'      then self.can_close = false
    when 'report'     then self.can_report = false
    when 'create'     then self.can_create = false
    when 'edit'       then self.can_edit = false
    when 'reassign'   then self.can_reassign = false
    when 'milestone'  then self.can_milestone = false
    when 'grant'      then self.can_grant = false
    when 'see_unwatched' then self.can_see_unwatched = false
    when 'all'        then
      self.can_comment = false
      self.can_work = false
      self.can_close = false
      self.can_report = false
      self.can_create = false
      self.can_edit = false
      self.can_reassign = false
      self.can_milestone = false
      self.can_grant = false
      self.can_see_unwatched = false
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

