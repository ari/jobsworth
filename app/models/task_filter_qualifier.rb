class TaskFilterQualifier < ActiveRecord::Base
  belongs_to :task_filter
  belongs_to :qualifiable, :polymorphic => true
end
