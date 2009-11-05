class Keyword < ActiveRecord::Base
  belongs_to :task_filter, :touch => true
  belongs_to :company
  
  validates_presence_of :company
  validates_presence_of :task_filter

  before_validation :set_company_from_task_filter

  private

  def set_company_from_task_filter
    if task_filter
      self.company = task_filter.company || task_filter.user.company
    end
  end

end
