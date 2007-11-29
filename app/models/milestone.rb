class Milestone < ActiveRecord::Base
  belongs_to :company
  belongs_to :project
  belongs_to :user

  has_many :tasks, :dependent => :nullify

  def completed_tasks
    @completed ||= Task.count( :conditions => ["milestone_id = ? AND completed_at is not null", self.id] ) * 1.0
  end
  def total_tasks
    @total ||= Task.count( :conditions => ["milestone_id = ?", self.id] ) * 1.0
  end

  def percent_complete
    p = 0.0

    complete = self.completed_tasks
    total =  self.total_tasks
    return 0.0 if total == 0
    p = (complete / total) * 100.0
  end

  def complete?
    (self.completed_tasks == self.total_tasks) || (!self.completed_at.nil?)
  end

  def to_tip(options = { })
    res = "<table cellpadding=0 cellspacing=0>"
    res << "<tr><th>#{_('Name')}</th><td> #{self.name}</td></tr>"
    res << "<tr><th>#{_('Due Date')}</th><td> #{self.due_at.strftime("%A, %d %B %Y")}</td></tr>" unless self.due_at.nil?
    res << "<tr><th>#{_('Owner')}</th><td> #{self.user.name}</td></tr>" unless self.user.nil?
    res << "<tr><th>#{_('Progress')}</th><td> #{self.completed_tasks.to_i} / #{self.total_tasks.to_i} #{_('Complete')}</td></tr>"
    res << "<tr><th>#{_('Description')}</th><td class=\"tip_description\">#{self.description.gsub(/\n/, '</td></tr>').gsub(/\"/,'&quot;')}</td></tr>" if( self.description && self.description.strip.length > 0)
    res << "</table>"
    res.gsub(/\"/,'&quot;')
  end


end
