# A saved filter which can be applied to a group of tasks

class View < ActiveRecord::Base

  belongs_to :user
  belongs_to :company

  has_and_belongs_to_many :property_values, :join_table => "views_property_values"

  ###
  # Sets any property values to use as filters on this view.
  ###
  def properties=(params)
    property_values.clear

    all_properties = company.properties

    params.each do |property_value_id|
      next if property_value_id.blank?

      pv = PropertyValue.find(property_value_id)
      if all_properties.index(pv.property)
        property_values << pv
      end
    end
  end
  
  ###
  # Returns the selected property value on this view for property.
  # (Or nil if none)
  ###
  def selected(property)
    return if !property

    property.property_values.detect { |pv| self.property_values.index(pv) }
  end

  ###
  # This method will help in the migration of type id, priority and severity
  # to use properties. It can be removed once that is done.
  ###
  def convert_attributes_to_properties
    all_properties = company.properties
    new_ids = []

    if filter_type_id != -1
      type = all_properties.detect { |t| t.name == "Type" }
      old = Task.issue_types[filter_type_id]
      new_ids << type.property_values.detect { |p| p.to_s == old }
    end

    if filter_priority != -10
      priority = all_properties.detect { |t| t.name == "Priority" }
      old = Task.priority_types[filter_priority]
      new_ids << priority.property_values.detect { |p| p.to_s == old }
    end

    if filter_severity != -10
      severity = all_properties.detect { |t| t.name == "Severity" }
      old = Task.severity_types[filter_severity]
      new_ids << severity.property_values.detect { |p| p.to_s == old }
    end

    self.properties = new_ids
  end

  ###
  # This method will migrate type id, priority and severity back from 
  # the properties to attributes.
  # It can be removed if we're happy with the migration to properties.
  ###
  def convert_properties_to_attributes
    all_properties = company.properties
    
    type = all_properties.detect { |t| t.name == "Type" }
    old_id = Task.issue_types.index(selected(type).to_s)
    self.filter_type_id = old_id || -1

    priority = all_properties.detect { |t| t.name == "Priority" }
    old_id = Task.priority_types.invert[selected(priority).to_s]
    self.filter_priority = old_id || -10

    severity = all_properties.detect { |t| t.name == "Severity" }
    old_id = Task.severity_types.invert[selected(severity).to_s]
    self.filter_severity = old_id || -10

    save
  end
end
