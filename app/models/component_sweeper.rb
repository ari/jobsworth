class ComponentSweeper < ActionController::Caching::Sweeper
    observe Task, Component, WorkLog, Sheet, Milestone
    
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
	tasks = Task.find(:all, :conditions => ["milestone_id = ? AND completed_at is null", record.id], :order => "component_id")
	
	tasks.each do |t|
	  expire_fragment( %r{tasks/task_row\.action_suffix=#{t.id}_.*} )
	  expire_fragment( %r{components/component_row\.action_suffix=#{t.component_id}_.*} )
	end
    end
    
    def expire_tree(record)

      if record.is_a?(Sheet)
	expire_fragment( %r{tasks/task_row\.action_suffix=#{record.task_id}_.*} )
	component = record.task.component
      elsif record.is_a?(WorkLog)
	expire_fragment( %r{tasks/task_row\.action_suffix=#{record.task_id}_.*} )
	expire_fragment( %r{log/component_log_row\.action_suffix=#{record.id}} )
	component = record.component
      elsif record.is_a?(Task)
	expire_fragment( %r{tasks/task_row\.action_suffix=#{record.id}_.*} )
	component = record.component
      else
	  component = record
      end

      while component
	expire_fragment( %r{components/component_row\.action_suffix=#{component.id}_.*} )
	expire_fragment( %r{components/component_info\.action_suffix=#{component.id}_.*} )
	if component.parent_id != 0
	  component = component.parent
	else
	  component = nil
	end
      end
    end
end

