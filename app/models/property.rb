class Property < ActiveRecord::Base
  belongs_to :company
  has_many :property_values, :dependent => :destroy

  def self.all_for_company(company)
    find(:all, :conditions => { :company_id => company.id })
  end
end
