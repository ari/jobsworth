class ConvertTypePrioritySeverityToProperties < ActiveRecord::Migration
  OLD_ISSUE_TYPES =  [ "Task", "New Feature", "Defect", "Improvement" ]
  OLD_PRIORITY_TYPES = { -2 => "Lowest", -1 => "Low", 0 => "Normal", 1 => "High", 2 => "Urgent", 3 => "Critical" }
  OLD_SEVERITY_TYPES = { -2 => "Trivial", -1 => "Minor", 0 => "Normal", 1 => "Major", 2 => "Critical", 3 => "Blocker" }

  def self.up
    Company.find(:all).each do |c|
      type, priority, severity = c.create_default_properties
      c.tasks.each do |t|
        t.convert_attributes_to_properties(type, priority, severity)
        t.save
      end
    end

    # create tables for filtering views on properties
    create_table :views_property_values, :id => false do |t|
      t.column :view_id, :integer
      t.column :property_value_id, :integer
    end
    add_index(:views_property_values, :view_id)
    add_index(:views_property_values, :property_value_id)

    # convert old views to use property values
    View.find(:all).each do |v|
      v.convert_attributes_to_properties
    end
  end

  def self.down
    Company.find(:all).each do |c|
      c.tasks.each do |t|
        t.convert_properties_to_attributes
        t.save
      end
    end

    # convert old views to use columns
    View.find(:all).each do |v|
      v.convert_properties_to_attributes
    end
    drop_table :views_property_values if table_exists?(:views_property_values)

    # remove created properties
    Company.find(:all).each do |c|
      c.type_property.destroy if c.type_property
      c.priority_property.destroy if c.priority_property
      c.severity_property.destroy if c.severity_property
    end

  end
end
