class Resource < ActiveRecord::Base
  belongs_to :company
  belongs_to :customer
  belongs_to :resource_type
  belongs_to :resource, :foreign_key => :parent_id
  has_many :resource_attributes

  validates_presence_of :company_id
end
