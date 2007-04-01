class Customer < ActiveRecord::Base
  belongs_to    :company
  has_many      :projects, :dependent => :destroy
  has_many      :work_logs
  has_many      :activities, :dependent => :destroy
  has_many      :project_files

  belongs_to    :binary, :dependent => :destroy

  validates_length_of           :name,  :maximum=>200
  validates_presence_of         :name

  validates_presence_of         :company_id

  def full_name
    if self.name == 'Internal' || self.name == self.company.name
      self.company.name
    else
      self.name
    end
  end


end
