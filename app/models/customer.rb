# A logical grouping of projects, called Client inside
# ClockingIT.

class Customer < ActiveRecord::Base
  belongs_to    :company
  has_many      :projects, :order => "name", :dependent => :destroy
  has_many      :work_logs
  has_many      :project_files

  validates_length_of           :name,  :maximum=>200
  validates_presence_of         :name

  validates_uniqueness_of       :name, :scope => 'company_id'
  
  validates_presence_of         :company_id

  after_destroy { |r|
    File.delete(r.logo_path) rescue begin end
  }

  def path
    File.join("#{RAILS_ROOT}", 'store', 'logos', self.company_id.to_s)
  end

  def store_name
    "logo_#{self.id}"
  end

  def logo_path
    File.join(self.path, self.store_name)
  end

  def full_name
    if self.name == 'Internal' || self.name == self.company.name
      self.company.name
    else
      self.name
    end
  end

  def logo?
    File.exist?(self.logo_path)
  end

end
