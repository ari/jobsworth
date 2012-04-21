# encoding: UTF-8
class Keyword < ActiveRecord::Base
  belongs_to :task_filter, :touch => true
  belongs_to :company

  validates_presence_of :company
  validates_presence_of :task_filter

  before_validation :set_company_from_task_filter

  scope :reversed, where(:reversed => true)

  private

  def set_company_from_task_filter
    if task_filter
      self.company = task_filter.company || task_filter.user.company
    end
  end

end






# == Schema Information
#
# Table name: keywords
#
#  id             :integer(4)      not null, primary key
#  company_id     :integer(4)
#  task_filter_id :integer(4)
#  word           :string(255)
#  created_at     :datetime
#  updated_at     :datetime
#  reversed       :boolean(1)      default(FALSE)
#
# Indexes
#
#  fk_keywords_task_filter_id  (task_filter_id)
#

