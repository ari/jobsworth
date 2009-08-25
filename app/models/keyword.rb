class Keyword < ActiveRecord::Base
  belongs_to :task_filter
  belongs_to :company
  
  validates_presence_of :company
  validates_presence_of :task_filter

  before_create :set_company_from_task_filter

  private

  def set_company_from_task_filter
    self.company = task_filter.company || task_filter.user.company
  end

end
