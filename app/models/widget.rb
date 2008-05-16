class Widget < ActiveRecord::Base
  belongs_to :company
  belongs_to :user

  validates_presence_of :name

  def name
    res = "#{@attributes['name']}"
    if self.filter_by?
      res << " - "
      begin
        res << case self.filter_by[0..0]
               when 'c'
                 User.find(self.user_id).company.customers.find(self.filter_by[1..-1]).name
               when 'p'
                 User.find(self.user_id).projects.find(self.filter_by[1..-1]).name
               when 'm'
                 m = Milestone.find(self.filter_by[1..-1], :conditions => ["project_id IN (#{User.find(self.user_id).projects.collect(&:id).join(',')})"])
                 "#{m.project.name} / #{m.name}"
               when 'u'
                 _('[Unassigned]')
               else 
                 ""
               end 
      rescue
        res << _("Invalid Filter")
      end 
    end 
    res << " [#{_'Mine'}]" if self.mine?
    res
  end
  
  def name=(arg)
    @attributes['name'] = arg
  end
  
end
