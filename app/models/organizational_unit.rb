# encoding: UTF-8
class OrganizationalUnit < ActiveRecord::Base
  has_many(:custom_attribute_values, :as => :attributable, :dependent => :destroy,
           # set validate = false because validate method is over-ridden and does that for us
           :validate => false)
  include CustomAttributeMethods

  belongs_to :customer
  scope :active, where(:active => true)

  validates_presence_of :name
  validates_presence_of :customer
  validate :validate_custom_attributes

  def company
    customer.company
  end

  def to_s
    res = name
    res ||= custom_attribute_values.first.value if custom_attribute_values.any?
    res ||= super

    return res
  end
end






# == Schema Information
#
# Table name: organizational_units
#
#  id          :integer(4)      not null, primary key
#  customer_id :integer(4)
#  created_at  :datetime
#  updated_at  :datetime
#  name        :string(255)
#  active      :boolean(1)      default(TRUE)
#
# Indexes
#
#  fk_organizational_units_customer_id  (customer_id)
#

