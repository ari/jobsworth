class ConvertTypePrioritySeverityToProperties < ActiveRecord::Migration
  OLD_ISSUE_TYPES =  [ "Task", "New Feature", "Defect", "Improvement" ]
  OLD_PRIORITY_TYPES = { -2 => "Lowest", -1 => "Low", 0 => "Normal", 1 => "High", 2 => "Urgent", 3 => "Critical" }
  OLD_SEVERITY_TYPES = { -2 => "Trivial", -1 => "Minor", 0 => "Normal", 1 => "Major", 2 => "Critical", 3 => "Blocker" }

  def self.up
    Company.find(:all).each do |c|
      type, priority, severity = c.create_default_properties
      
      c.tasks.each do |t|
        copy_task_value(t, t.issue_type, type)
        copy_task_value(t, t.priority_type, priority)
        copy_task_value(t, t.severity_type, severity)
      end
    end

    remove_column Task.table_name, :priority
    remove_column Task.table_name, :severity_id
    remove_column Task.table_name, :type_id

    create_table :views_property_values, :id => false do |t|
      t.column :view_id, :integer
      t.column :property_value_id, :integer
    end
    add_index(:views_property_values, :view_id)
    add_index(:views_property_values, :property_value_id)
  end

  def self.down
    drop_table :views_property_values

    add_column Task.table_name, :priority, :integer, :default => 0
    add_column Task.table_name, :severity_id, :integer, :default => 0
    add_column Task.table_name, :type_id, :integer, :default => 0

    Company.find(:all).each do |c|
      type, priority, severity = Property.defaults
      type = c.properties.find_by_name(type.first[:name])
      severity = c.properties.find_by_name(severity.first[:name])
      priority = c.properties.find_by_name(priority.first[:name])
      
      # copy property values back to old columns
      c.tasks.each do |t|
        task_type = t.property_value(type)
        t.type_id = OLD_ISSUE_TYPES.index(task_type.value) if task_type
        t.type_id ||= 0

        task_priority = t.property_value(priority)
        t.priority = old_id_for(task_priority, OLD_PRIORITY_TYPES) if task_priority

        task_severity = t.property_value(severity)
        t.severity_id = old_id_for(task_severity, OLD_SEVERITY_TYPES) if task_severity

        t.save
      end

      type.destroy if type
      priority.destroy if priority
      severity.destroy if severity
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

  def self.old_id_for(new_value, old_values)
    match = old_values.select { |k, v| v == new_value.value }
    return match.first.first if match.first
  end
end
