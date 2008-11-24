# A tag belonging to a company and task

class Tag < ActiveRecord::Base

  belongs_to :company
  has_and_belongs_to_many      :tasks, :join_table => :task_tags

  def count
    tasks.count(:conditions => "tasks.completed_at IS NULL")
  end

  def total_count
    tasks.count
  end

  def Tag.top_counts(options = {})

    task_ids = ''
    if options[:filter_user].to_i > 0
      task_ids = User.find(options[:filter_user].to_i).tasks.collect { |t| t.id }.join(',')
    end

    if options[:filter_user].to_i < 0
      task_ids = Task.find(:all, :select => "tasks.*", :joins => "LEFT OUTER JOIN task_owners t_o ON tasks.id = t_o.task_id", :conditions => ["tasks.company_id = ? AND t_o.id IS NULL", options[:company_id]]).collect { |t| t.id }.join(',')
    end

    task_ids_str = "tasks.id IN (#{task_ids})" if task_ids != ''
    task_ids_str = "tasks.id = 0" if task_ids == ''

    @completed_milestone_ids = Milestone.find(:all, :conditions => ["company_id = ? AND completed_at IS NOT NULL", options[:company_id]]).collect{ |m| m.id }.join(',')
    @completed_milestone_ids = "-1" if @completed_milestone_ids == ''


    conditions = []
    conditions << "tags.company_id = #{options[:company_id]}" if options[:company_id]
    conditions << "tasks.project_id IN (#{options[:project_ids]})" if options[:project_ids]
    conditions << "#{task_ids_str}" unless options[:filter_user].to_i == 0
    conditions << "tasks.milestone_id = #{options[:filter_milestone]}" if options[:filter_milestone].to_i > 0
    conditions << "tasks.milestone_id IS NULL" if options[:filter_milestone].to_i < 0
    conditions << "(tasks.milestone_id NOT IN (#{@completed_milestone_ids}) OR tasks.milestone_id IS NULL)"
    conditions << "tasks.hidden = 0" if options[:filter_status].to_i != -2
    conditions << "tasks.hidden = 1" if options[:filter_status].to_i == -2
    if options[:filter_customer].to_i > 0
      conditions << "projects.customer_id = #{options[:filter_customer]}"
      conditions << "tasks.project_id = projects.id"
    end 
    conditions << "tags.name LIKE '#{options[:like]}%'" if options[:like]
    conditions << "tags.id = task_tags.tag_id"
    conditions << "tasks.id = task_tags.task_id"
    Tag.count("tags.name", :conditions => conditions.join(' AND '), :joins => (options[:filter_customer].to_i > 0 ? ", task_tags, tasks, projects" : ", task_tags, tasks"), :group => "tags.name", :order => "count_tags_name desc,tags.name")
  end

  def to_s
    self.name
  end

end
