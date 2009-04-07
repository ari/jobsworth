class OrganizationalUnit < ActiveRecord::Base
  has_many :custom_attribute_values, :as => :attributable, :dependent => :destroy
  include CustomAttributeMethods

  belongs_to :customer

  def company
    customer.company
  end

  def to_s
    if custom_attribute_values.any?
      return custom_attribute_values.first.value
    else
      super
    end
  end
end
