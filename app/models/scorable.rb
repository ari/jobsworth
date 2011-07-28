module Scorable
  def self.included(class_name)
    # Creates a score_rules association on the class
    # represented by 'class_name'
    class_name.class_eval do
      has_many  :score_rules, :as => :controlled_by
    end 
  end

  private
  # This method was supposed to be called when a 
  # new score rule was added, but due to performance
  # issues, as for now, it will not
  def update_tasks_score(new_score_rule)
    Task.open_only.each do |task|
      task.update_score_with new_score_rule 
      task.save
    end
  end
end
