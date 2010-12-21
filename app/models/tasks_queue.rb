# encoding: UTF-8
require "#{Rails.root}/config/formula.rb"
class TasksQueue
  def self.calculate(company_or_user)
    company_or_user.tasks.open.each{ |task|
      formula(task)
      task.save
    }
  end
  def self.tasks_for_user(user)
    user.tasks.open.order("(weight + weight_adjustment) desc").limit(5)
  end
end
