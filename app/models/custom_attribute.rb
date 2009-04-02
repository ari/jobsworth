class CustomAttribute < ActiveRecord::Base
  validates_presence_of :attributable_type
  validates_presence_of :display_name

  ###
  # Returns the custom attributes that should be display for 
  # the given class (or object).
  ###
  def self.attributes_for(klass)
    if klass.class.name != "Class"
      klass = klass.class 
    end

    CustomAttribute.find(:all, 
                         :conditions => { :attributable_type => klass.name },
                         :order => "position")
  end
end
