# A widget on the Activities page.


class Widget < ActiveRecord::Base
  belongs_to :company
  belongs_to :user

  validates_presence_of :name

  def name
    res = ""
    if self.filter_by && self.filter_by.length > 0
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
    "#{@attributes['name']}#{ res.empty? ? "" : " - #{res}"}"
  end
  
#  def name=(arg)
#    self.attributes['name'] = arg
#  end

  
end

# == Schema Information
#
# Table name: widgets
#
#  id          :integer(4)      not null, primary key
#  company_id  :integer(4)
#  user_id     :integer(4)
#  name        :string(255)
#  widget_type :integer(4)      default(0)
#  number      :integer(4)      default(5)
#  mine        :boolean(1)
#  order_by    :string(255)
#  group_by    :string(255)
#  filter_by   :string(255)
#  collapsed   :boolean(1)      default(FALSE)
#  column      :integer(4)      default(0)
#  position    :integer(4)      default(0)
#  configured  :boolean(1)      default(FALSE)
#  created_at  :datetime
#  updated_at  :datetime
#  gadget_url  :text
#

