class Resource < ActiveRecord::Base
  belongs_to :company
  belongs_to :customer
  belongs_to :resource_type
  belongs_to :parent, :class_name => "Resource"
  has_many(:resource_attributes, 
           :include => :resource_type_attribute,
           :dependent => :destroy)

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

      attr = resource_attributes.detect { |a| a.id == attr_id.to_i }
      attr ||= build_new_attribute(values)

      attr.update_attributes(values)
      updated << attr
    end
    
    missing = resource_attributes - updated
    resource_attributes.delete(missing)
  end

  ###
  # This method returns an array of ResourceAttributes.
  # These attributes are sorted according the to this objects
  # ResourceType.
  # If a value if missing, a new ResourceAttribute will be created
  # but not saved.
  ###
  def all_attributes
    res = []
    resource_type.resource_type_attributes.each do |rta|
      attrs = resource_attributes.select { |a| a.resource_type_attribute_id == rta.id }
      if attrs.empty?
        res << ResourceAttribute.new(:resource_type_attribute_id => rta.id)
      else
        res += attrs
      end
    end

    return res
  end

  ###
  # Checks all attributes are valid
  ###
  def validate
    res = true

    resource_attributes.each do |attr|
      res &&= attr.valid?
    end

    return res
  end

  private

  ###
  # Returns a new resource_attribute linked to this
  # resource. 
  ###
  def build_new_attribute(values)
    attr_type_id = values[:resource_type_attribute_id]
    
    # check we're using attributes from this company
    rtas = []
    company.resource_types.each { |rt| rtas += rt.resource_type_attributes }

    rta = rtas.detect { |rta| rta.id == attr_type_id.to_i }
    if rta
      return resource_attributes.build 
    end
  end
end
