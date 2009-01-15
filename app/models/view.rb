# A saved filter which can be applied to a group of tasks

class View < ActiveRecord::Base

  belongs_to :user
  belongs_to :company

  has_and_belongs_to_many :property_values, :join_table => "views_property_values"

  def properties=(params)
    property_values.clear

    all_properties = Property.all_for_company(company)

    params.each do |property_value_id|
      next if property_value_id.blank?

      pv = PropertyValue.find(property_value_id)
      if all_properties.index(pv.property)
        property_values << pv
      end
    end
  end
  
  def selected(property)
    property.property_values.detect { |pv| self.property_values.index(pv) }
  end
end
