class OrganizationalUnit < ActiveRecord::Base
  has_many :custom_attribute_values, :as => :attributable, :dependent => :destroy
  include CustomAttributeMethods

  belongs_to :customer

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
