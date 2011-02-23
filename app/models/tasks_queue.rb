# encoding: UTF-8
require "#{Rails.root}/config/formula.rb"
class TasksQueue
  def self.calculate(company_or_user)
    company_or_user.tasks.open.each{ |task|
      calculate_one(task)
    }
    company_or_user.tasks.open.joins(:dependants).each{ |task|
      task.weight += calculate_dependants_weight(task.dependants)
      task.save!
    }
  end
  def self.calculate_one(task)
    formula(task)
    task.save
  end
  def self.tasks_for_user(user)
    user.tasks.open.order("(weight + weight_adjustment) desc").limit(50)
  end
end

def calculate_dependants_weight(tasks)
  return 0 if tasks.empty?
  return tasks.inject(0){ |sum, task|
    sum +  (task.dependants.empty? ?  task.weight : task.weight + calculate_dependants_weight(task.dependants))
  }
end
