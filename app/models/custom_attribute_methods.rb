module CustomAttributeMethods

  ###
  # Returns the custom attributes that should be displayed for 
  # the current objects class.
  ###
  def available_custom_attributes
    company.custom_attributes.find(:all, 
                                   :conditions => { :attributable_type => self.class.name },
                                   :order => "position")
  end

  ###
  # Returns an array of the custom attributes values defined for the current
  # object. This will include *at least* the ones defined in 
  # available_custom_attributes. 
  #
  # If there are multiple values defined for one attribute type, they 
  # will be returned as a nested array.
  #
  ###
  def all_custom_attribute_values
    res = []

    available_custom_attributes.each do |attr|
      conds = { :attributable_type => self.class.name, :attributable_id => self.id }
      existing = custom_attribute_values.select do |cav|
        cav.custom_attribute == attr
      end

      if existing.empty?
        res << attr.custom_attribute_values.build(conds.merge(:custom_attribute_id => attr.id))
      else
        res += existing
      end
    end
    
    return res
  end

  ###
  # Sets up attribute values for this object.
  # Any existing attribute values that are defined, but not
  # passed in will be removed.
  ###
  def set_custom_attribute_values=(params)
    updated = []
    existing = custom_attribute_values.clone

    params.each do |values|
      attr_id = values[:custom_attribute_id]

      # find an existing value
      cav = existing.detect { |v| v.custom_attribute_id == attr_id.to_i }
      existing.delete(cav)

      # create a new one if none found
      cav ||= custom_attribute_values.build(:custom_attribute_id => attr_id)

      cav.attributes = values
      if !new_record?
        cav.save
      end
      updated << cav
    end
    
    # anything still in existing_values hasn't been updated, so delete.
    missing = custom_attribute_values - updated
    custom_attribute_values.delete(missing)
  end

  ###
  # Returns an array of strings that are currently selected
  # for the given attribute.
  ###
  def values_for(attribute)
    vals = custom_attribute_values.select { |cav| cav.custom_attribute == attribute }
    return vals.map do |cav|
      if cav.choice
        cav.choice.value
      else
        cav.value
      end
    end
  end

  ###
  # Checks if this object, and all associated values are valid. Adds errors
  # to base if not.
  ###
  def validate
    valid = true

    invalid = custom_attribute_values.select { |cav| !cav.valid? }

    if invalid.any?
      valid = false

      invalid.each do |cav|
        cav.errors.each do |attr, err|
          errors.add_to_base(err)
        end
      end
    end

    return valid
  end
end
