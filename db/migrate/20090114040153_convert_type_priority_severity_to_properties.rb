class ConvertTypePrioritySeverityToProperties < ActiveRecord::Migration
  def self.up
    deactivate_project_stat_counts

    add_column Property.table_name, :default_sort, :boolean unless Property.column_names.include?('default_sort')
    add_column Property.table_name, :default_color, :boolean unless Property.column_names.include?('default_color')
    change_column PropertyValue.table_name, :default, :boolean

    Property.reset_column_information

    Company.all.each do |c|
      type, priority, severity = c.create_default_properties
      c.tasks.each_with_index do |t, i|
        next if t.property_value(severity) and t.property_value(priority) and t.property_value(type)
        t.convert_attributes_to_properties(type, priority, severity)
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
    View.all.each do |v|
      v.convert_attributes_to_properties
    end

    reactivate_project_stat_counts
  end

  def self.down
    deactivate_project_stat_counts

    Company.all.each do |c|
      c.tasks.each do |t|
        t.convert_properties_to_attributes
        t.save
      end
    end

    # convert old views to use columns
    View.all.each do |v|
      v.convert_properties_to_attributes
    end
    drop_table :views_property_values if table_exists?(:views_property_values)

    # remove created properties
    Company.all.each do |c|
      c.type_property.destroy if c.type_property
      c.priority_property.destroy if c.priority_property
      c.severity_property.destroy if c.severity_property
    end

    remove_column Property.table_name, :default_sort
    remove_column Property.table_name, :default_color

    reactivate_project_stat_counts
  end

  def self.deactivate_project_stat_counts
    Project.class_eval do
      alias :old_update_project_stats :update_project_stats
      def update_project_stats
        # do nothing
      end
    end
  end

  def self.reactivate_project_stat_counts
    Project.class_eval do
      alias :update_project_stats :old_update_project_stats
    end

    Project.all.each do |p| 
      p.update_project_stats
      p.save
    end
  end
end
