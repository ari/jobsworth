class Property < ActiveRecord::Base
  belongs_to :company
  has_many :property_values, :order => "position asc, id asc", :dependent => :destroy

  def self.all_for_company(company)
    find(:all, :conditions => { :company_id => company.id })
  end

  def filter_name
    @filter_name ||= "property_filter_#{ id }"
  end
end
