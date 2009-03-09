class Resource < ActiveRecord::Base
  belongs_to :company
  belongs_to :customer
  belongs_to :resource_type
  belongs_to :parent, :class_name => "Resource"
  has_many(:resource_attributes, 
           :include => :resource_type_attribute,
           :order => "#{ ResourceTypeAttribute.table_name }.position asc, id asc")

  validates_presence_of :company_id
  validates_presence_of :resource_type_id

  ###
  # Sets up attribute values for this resource using params.
  # Any existing values for resource attribute types defined
  # for this resource but not passed in will be removed.
  ###
  def attribute_values=(params)
    updated = []
    params.each do |values|
      attr_id = values[:id]

      if !attr_id
        attr_type_id = values[:resource_type_attribute_id]
        rta = resource_type.resource_type_attributes.find(attr_type_id)
        attr = resource_attributes.build
      else
        attr = resource_attributes.detect { |a| a.id == attr_id.to_i }
      end

      attr.update_attributes(values)
      updated << attr
    end
    
    missing = resource_attributes - updated
    resource_attributes.delete(missing)
  end
end
