class CustomAttributeValue < ActiveRecord::Base
  belongs_to :attributable, :polymorphic => true
  belongs_to :custom_attribute
end
