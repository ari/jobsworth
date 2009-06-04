class CustomAttributeChoice < ActiveRecord::Base
  belongs_to :custom_attribute
  
  validates_presence_of :value
end
