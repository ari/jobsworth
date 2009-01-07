###
# A PropertyValue is a potential value a property can take.
#
# Examples of PropertyValues include High, Medium, Low, In progress.
###
class PropertyValue < ActiveRecord::Base
  belongs_to :property

  def to_s
    value
  end
end
