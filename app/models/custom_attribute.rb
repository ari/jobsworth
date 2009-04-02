class CustomAttribute < ActiveRecord::Base
  validates_presence_of :attributable_type
  validates_presence_of :display_name
  validates_presence_of :company_id

  belongs_to :company
  has_many :custom_attribute_values
  belongs_to :attributable, :polymorphic => true
end
