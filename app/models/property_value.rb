###
# A PropertyValue is a potential value a property can take.
#
# Examples of PropertyValues include High, Medium, Low, In progress.
###
class PropertyValue < ActiveRecord::Base
  belongs_to :property

  ###
  # Returns an int to use for sorting tasks with
  # this property value.
  ###
  def sort_rank
    @sort_rank ||= (property.property_values.length - property.property_values.index(self))
  end

  def to_s
     HTML::FullSanitizer.new.sanitize "#{ value }"
  end

  def to_html
    if icon_url.present?
      return image_tag(icon_url, :class => "tooltip",
                       :alt => self.to_s, :title => self.to_s)
    else
      return self.to_s
    end
  end

  private

  include ActionView::Helpers::AssetTagHelper

end

# == Schema Information
#
# Table name: property_values
#
#  id          :integer(4)      not null, primary key
#  property_id :integer(4)
#  value       :string(255)
#  color       :string(255)
#  default     :boolean(1)
#  position    :integer(4)
#  created_at  :datetime
#  updated_at  :datetime
#  icon_url    :string(1000)
#

