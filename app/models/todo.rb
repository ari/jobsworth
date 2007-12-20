class Todo < ActiveRecord::Base
  belongs_to :company
  belongs_to :task

  acts_as_list :scope => 'task_id = #{task_id} AND completed_at IS NULL'

  def done?
    self.completed_at != nil
  end

  def done
    self.done?
  end

  def css_classes
    if self.done?
      "todo todo-completed"
    else
      "todo todo-active"
    end
  end
end
