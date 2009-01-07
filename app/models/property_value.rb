class PropertyValue < ActiveRecord::Base
  belongs_to :property

  def to_s
    value
  end
end
