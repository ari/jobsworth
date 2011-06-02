class WorkingHoursFormatValidator < ActiveModel::EachValidator  
  def validate_each(object, attribute, value)  
    unless value =~ /^\d+\.\d+\|\d+\.\d+\|\d+\.\d+\|\d+\.\d+\|\d+\.\d+\|\d+\.\d+\|\d+\.\d+$/
      object.errors[attribute] << (options[:message] || "is not formatted properly")
    end  
  end  
end
