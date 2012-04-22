# encoding: UTF-8
class ResourceType < ActiveRecord::Base
  belongs_to :company
  has_many(:resource_type_attributes, :order => "position", 
           :dependent => :destroy)

  validates_presence_of :name

  ###
  # Creates new resource type attributes from params.
  ###
  def new_type_attributes=(params)
    params.each do |attr|
      resource_type_attributes.build(attr)
    end
  end

  ###
  # Updates existing attributes from params.
  # The order of attributes in params is used to set position.
  # If an attribute is missing from params, it will be removed.
  ###
  def type_attributes=(params)
    updated = []

    params.keys.each_with_index do |id, i|
      existing = resource_type_attributes.detect { |rta| rta.id == id.to_i }

      existing.update_attributes(params[id])
      updated << existing
    end

    missing = resource_type_attributes - updated
    missing.delete_if { |rta| rta.new_record? }

    resource_type_attributes.delete(missing)
  end
end






# == Schema Information
#
# Table name: resource_types
#
#  id         :integer(4)      not null, primary key
#  company_id :integer(4)
#  name       :string(255)
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  fk_resource_types_company_id  (company_id)
#

