class TaskFilterQualifier < ActiveRecord::Base
  attr_accessor :task_num

  belongs_to :task_filter
  belongs_to :qualifiable, :polymorphic => true
  validates_presence_of :qualifiable

  before_validation :set_qualifiable_from_task_num

  private

  def set_qualifiable_from_task_num
    return if task_num.blank?

    task = task_filter.company.tasks.find_by_task_num(task_num)
    if task and task_filter.user.can_view_task?(task)
      self.qualifiable = task
    end
  end

end
