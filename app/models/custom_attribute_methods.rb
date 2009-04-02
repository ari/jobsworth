module CustomAttributeMethods
  ###
  # Returns the custom attributes that should be displayed for 
  # the current class.
  ###
  def available_custom_attributes
    CustomAttribute.find(:all, 
                         :conditions => { :attributable_type => self.class.name },
                         :order => "position")
  end

end
