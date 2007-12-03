class Tag < ActiveRecord::Base

  belongs_to :company
  has_and_belongs_to_many      :tasks, :join_table => :task_tags


  def exists?
    tag = Tag.find(:first, :conditions => ["company_id = ? AND name = ?", self.company_id, self.name])
    !tag.nil?
  end

#  def count
#    count = Tag.count_with_tag(self)
#  end

  def Tag.count_with_tag(tag)
    tags = []
    if tag.is_a? Tag
      tags = [tag.name]
    elsif tag.is_a? String
      tags = tag.include?(",") ? tag.split(',') : [tag]
    elsif tag.is_a? Array
      tags = tag
    end

    sql = "SELECT count(tasks.*) from task_tags, tasks, tags WHERE task_tags.tag_id=tags.id AND tasks.id = task_tags.task_id"
    sql << " AND (" + tags.collect { |t| ["tags.name='#{t.downcase.strip}'"] }.join(" OR ") + ")"
    sql << " AND tasks.company_id=#{session[:company].id}"
    sql << " GROUP BY tasks.id"
    sql << " HAVING COUNT(tasks.id) = #{tags.size}"

    count_by_sql(sql)
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
    conditions << "projects.customer_id = #{options[:filter_customer]}" if options[:filter_customer].to_i > 0
    conditions << "tags.name LIKE '#{options[:like]}%'" if options[:like]
    conditions << "tags.id = task_tags.tag_id"
    conditions << "tasks.id = task_tags.task_id"
    conditions << "projects.id = tasks.project_id"
    Tag.count("tags.name", :conditions => conditions.join(' AND '), :joins => ", task_tags, tasks, projects", :group => "tags.name", :order => "count_tags_name desc,tags.name")
  end

  def to_s
    self.name
  end

end
