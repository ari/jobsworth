# encoding: UTF-8
require "#{Rails.root}/config/formula.rb"
class TasksQueue
  def self.calculate(company_or_user)
    company_or_user.tasks.open.each{ |task|
      calculate_one(task)
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
