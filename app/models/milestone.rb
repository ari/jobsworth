class Milestone < ActiveRecord::Base
  belongs_to :company
  belongs_to :project
  belongs_to :user

  has_many :tasks, :dependent => :nullify

  def completed_tasks
    @completed ||= Task.count( ["milestone_id = ? AND completed_at is not null", self.id] ) * 1.0
  end
  def total_tasks
    @total ||= Task.count( ["milestone_id = ?", self.id] ) * 1.0
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
    res = ""
    res << "<strong>#{_('Name')}</strong> #{self.name}<br />"
    res << "<strong>#{_('Due Date')}</strong> #{self.due_at.strftime("%A, %d %B %Y")}<br/>" unless self.due_at.nil?
    res << "<strong>#{_('Owner')}</strong> #{self.user.name}<br />" unless self.user.nil?
    res << "<strong>#{_('Progress')}</strong> #{self.completed_tasks.to_i} / #{self.total_tasks.to_i} #{_('Complete')}"
    res << "<div class=tip_description> #{self.description.gsub(/\n/, '<br/>').gsub(/\"/,'&quot;')}</div>" if( self.description && self.description.strip.length > 0)
    res
  end


end
