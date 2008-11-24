# Permissions for a User on a Project

class ProjectPermission < ActiveRecord::Base
  belongs_to :company
  belongs_to :project
  belongs_to :user

  def can? (perm)
    case perm
    when 'comment'    then self.can_comment?
    when 'work'       then self.can_work?
    when 'close'      then self.can_close?
    when 'report'     then self.can_report?
    when 'create'     then self.can_create?
    when 'edit'       then self.can_edit?
    when 'reassign'   then self.can_reassign?
    when 'prioritize' then self.can_prioritize?
    when 'milestone'  then self.can_milestone?
    when 'grant'      then self.can_grant?
    when 'all'        then (self.can_comment? && self.can_work? && self.can_close? && self.can_report? && self.can_create? && self.can_edit? &&
            self.can_reassign? && self.can_prioritize? && self.can_milestone? && self.can_grant?)
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
    when 'prioritize' then self.can_prioritize = 1
    when 'milestone'  then self.can_milestone = 1
    when 'grant'      then self.can_grant = 1
    when 'all'        then
      self.can_comment = 1
      self.can_work = 1
      self.can_close = 1
      self.can_report = 1
      self.can_create = 1
      self.can_edit = 1
      self.can_reassign = 1
      self.can_prioritize = 1
      self.can_milestone = 1
      self.can_grant = 1
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
    when 'prioritize' then self.can_prioritize = 0
    when 'milestone'  then self.can_milestone = 0
    when 'grant'      then self.can_grant = 0
    when 'all'        then
      self.can_comment = 0
      self.can_work = 0
      self.can_close = 0
      self.can_report = 0
      self.can_create = 0
      self.can_edit = 0
      self.can_reassign = 0
      self.can_prioritize = 0
      self.can_milestone = 0
      self.can_grant = 0
    end
  end


end

