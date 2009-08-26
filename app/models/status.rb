class Status < ActiveRecord::Base
  belongs_to :company
  validates_presence_of :company

  # Creates the default statuses expected in the system 
  def self.create_default_statuses(company)
    company.statuses.build(:name => "Open").save!
    company.statuses.build(:name => "In Progress").save!
    company.statuses.build(:name => "Closed").save!
    company.statuses.build(:name => "Won't fix").save!
    company.statuses.build(:name => "Invalid").save!
    company.statuses.build(:name => "Duplicate").save!
  end

  def to_s
    name
  end

end
