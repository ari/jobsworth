class ConvertTypePrioritySeverityToProperties < ActiveRecord::Migration
  def self.up
    Company.find(:all).each do |c|
      task, severity, priority = c.create_default_properties
      
      c.tasks.each do |t|
        copy_task_value(t, t.issue_type, task)
        copy_task_value(t, t.severity_type, severity)
        copy_task_value(t, t.priority_type, priority)
      end
    end
  end

  def self.down
    Company.find(:all).each do |c|
      Property.defaults.each do |property_params, val_params|
        name = property_params[:name]
        prop = c.properties.find_by_name(name)
        prop.destroy if prop
      end
    end
  end

  ###
  # Copies the severity, priority etc on the given task to the new
  # property.
  ###
  def self.copy_task_value(task, old_value, new_property)
    return if !old_value

    matching_value = new_property.property_values.detect { |pv| pv.value == old_value }
    task.set_property_value(new_property, matching_value) if matching_value
  end

end
