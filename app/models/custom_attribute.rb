class CustomAttribute < ActiveRecord::Base
  validates_presence_of :attributable_type
  validates_presence_of :display_name
  validates_presence_of :company_id

  belongs_to :company
  has_many :custom_attribute_values, :dependent => :destroy
  belongs_to :attributable, :polymorphic => true

  ###
  # Returns the attributes setup for the given type in company.
  ###
  def self.attributes_for(company, type)
    conds = { :attributable_type => type }
    return company.custom_attributes.find(:all, :order => "position", 
                                          :conditions => conds)
  end
end
