# encoding: UTF-8
class Resource < ActiveRecord::Base
  include ERB::Util

  belongs_to :company
  belongs_to :customer
  belongs_to :resource_type
  belongs_to :parent, :class_name => "Resource"
  has_many(:child_resources, :class_name => "Resource",
           :foreign_key => "parent_id",
           :order => "lower(name)")
  has_many(:resource_attributes,
           :include => :resource_type_attribute,
           :dependent => :destroy)
  has_many :event_logs, :as => :target, :order => "updated_at desc"
  has_and_belongs_to_many :tasks, :join_table=>:resources_tasks

  validates_presence_of :company_id
  validates_presence_of :resource_type_id
  validates_presence_of :name
  validate :validate_attributes

  FILTERABLE = [ :customer_id, :resource_type_id ]

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

      attr.attributes = values
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
    return [] if resource_type.blank?

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
  # Returns an array of strings that describe any
  # unsaved changes to the current resource
  ###
  def changes_as_html
    res = []
    self.changes.each do |name, values|
      old_value = values[0]
      new_value = values[1]

      str = "<strong>#{ h(name.humanize) }</strong>: "
      str += "#{ h(old_value) } -> #{ h(new_value) }"

      res << str
    end

    return res
  end

  ###
  # Checks all attributes are valid
  ###
  def validate_attributes
    # check customer is present
    res = !customer.nil?
    errors.add(:base, _("Client can't be blank")) if customer.nil?

    # check attributes are valid
    invalid = resource_attributes.select { |attr| !attr.check_regex }
    res = invalid.empty?

    # add errors for any invalid attributes
    invalid.each do |attr|
      msg = "#{ attr.resource_type_attribute.name } doesn't match regex"
      errors.add(:base, msg)
    end

    if resource_type
      # check for missing mandatory attributes
      resource_type.resource_type_attributes.each do |rta|
        next if !rta.is_mandatory?

        attr = resource_attributes.detect { |ra| ra.resource_type_attribute == rta }
        value = attr.value if attr
        if value.blank?
          res = false
          errors.add(:base, "Missing value for mandatory #{ rta.name }")
        end
      end
    end

    return res
  end

  def to_s
    name
  end

  def to_url
    { :action => "edit", :controller => "resources", :id => id }
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






# == Schema Information
#
# Table name: resources
#
#  id               :integer(4)      not null, primary key
#  company_id       :integer(4)
#  resource_type_id :integer(4)
#  parent_id        :integer(4)
#  name             :string(255)
#  customer_id      :integer(4)
#  notes            :text
#  created_at       :datetime
#  updated_at       :datetime
#  active           :boolean(1)      default(TRUE)
#
# Indexes
#
#  fk_resources_company_id  (company_id)
#

