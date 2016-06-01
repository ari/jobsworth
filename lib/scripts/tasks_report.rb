require 'rubygems'
require 'active_record'
require 'active_support'
require 'action_view'
require 'erb'
require 'yaml'
require 'activerecord-jdbcmysql-adapter'

config = YAML.load(ERB.new(File.new('config/database.yml').read).result(binding))[ENV['RAILS_ENV']]
ActiveRecord::Base.establish_connection(config)

class AbstractTask < ActiveRecord::Base
  self.table_name = 'tasks'
  self.inheritance_column = nil
  has_many      :owners, through: :task_owners, source: :user
  has_many      :task_owners, dependent: :destroy, foreign_key: 'task_id'
  has_many      :work_logs, -> { order('started_at asc') }, dependent: :destroy, foreign_key: 'task_id'

  COMPANY_ID = 953
  LAST_WEEK = (Time.now - 1.week)..Time.now
  REPORT_STATUSES = {0 => :open, 1 => :closed, 2 => :high, 3 => :invalid, 4 => :duplicate}
  REPORT_PRIORITY = {0 => :critical, 1 => :urgent, 2 => :high, 3 => :normal, 4 => :low, 5 => :lowest}
  scope :opened, -> { where(status: REPORT_STATUSES.key(:open), company_id: COMPANY_ID, created_at: LAST_WEEK)}
  scope :closed, -> { where(status: REPORT_STATUSES.key(:closed), company_id: COMPANY_ID, completed_at: LAST_WEEK)}
  scope :other, -> { where(company_id: COMPANY_ID, completed_at: nil).where.not(created_at: LAST_WEEK) }
end

class TaskRecord < AbstractTask
end

class TaskUser < ActiveRecord::Base
  belongs_to :user
  belongs_to :task, class_name: 'AbstractTask'
end

class TaskOwner < TaskUser
end

class User < ActiveRecord::Base
  has_many      :tasks, through: :task_owners, class_name: 'TaskRecord'
  has_many      :task_owners, dependent: :destroy
  has_many      :work_logs
end

class WorkLog < ActiveRecord::Base
  belongs_to :task, class_name: 'AbstractTask', foreign_key: 'task_id'
  belongs_to :user, class_name: 'User', foreign_key: 'user_id'
end

erb = ERB.new(File.open("#{__dir__}/tasks.html.erb").read)
print erb.result binding

