
class CacheSweeper < ActionController::Caching::Sweeper
    observe Task, WorkLog, Sheet, Milestone

    def after_save(record)
      if record.is_a?(Milestone)
        expire_milestone(record)
      else
        expire_tree( record )
      end
    end

    def before_destroy(record)
      if record.is_a?(Milestone)
        expire_milestone(record)
      else
        expire_tree( record )
      end
    end

    def expire_milestone(record)
        tasks = Task.find(:all, :conditions => ["milestone_id = ? AND completed_at is null", record.id])

        tasks.each do |t|
          expire_fragment( %r{tasks/task_row\.action_suffix=#{t.id}_.*} )
        end
    end

    def expire_tree(record)

      if record.is_a?(Sheet)
        expire_fragment( %r{tasks/task_row\.action_suffix=#{record.task_id}_.*} )
      elsif record.is_a?(WorkLog)
        expire_fragment( %r{tasks/task_row\.action_suffix=#{record.task_id}_.*} )
      elsif record.is_a?(Task)
        expire_fragment( %r{tasks/task_row\.action_suffix=#{record.id}_.*} )
      end

    end
end

