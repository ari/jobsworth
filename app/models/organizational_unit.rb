class OrganizationalUnit < ActiveRecord::Base
  has_many(:custom_attribute_values, :as => :attributable, :dependent => :destroy, 
           # set validate = false because validate method is over-ridden and does that for us
           :validate => false)
  include CustomAttributeMethods

  belongs_to :customer
  named_scope :active, :conditions => { :active => true }

  validates_presence_of :name

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
