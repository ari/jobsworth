# Search across all WorkLogs and Tasks
class SearchController < ApplicationController

  def search

    @tasks = []
    @logs = []
    @shouts = []

    return if params[:query].nil? || params[:query].length == 0

    @keys = params[:query].split(' ')
    @keys ||= []
    
    # Looking up a task by number?
    task_num = params[:query][/#[0-9]+/]
    unless task_num.nil?
      @tasks = Task.find(:all, :conditions => ["company_id = ? AND project_id IN (#{current_project_ids}) AND task_num = ?", current_user.company_id, task_num[1..-1]])
      redirect_to :controller => 'tasks', :action => 'edit', :id => @tasks.first
    end

    query = ""
    @keys.each do |k|
      query << "+*:#{k}* "
    end

    # Append project id's the user has access to
    projects = ""

    session[:completed_projects] = params[:completed_projects] if request.post?
    
    if session[:completed_projects].to_i == 1 
      target_projects = all_projects
    end
    target_projects ||= current_projects

    target_projects.each do |p|
      projects << "|" unless projects == ""
      projects << "#{p.id}"
    end
    projects = "+project_id:\"#{projects}\"" unless projects == ""

    # Find the tasks
    @tasks = Task.find_by_contents("+company_id:#{current_user.company_id} #{projects} #{query}", {:limit => 1000})

    # Find the worklogs
    @logs = WorkLog.find_by_contents("+company_id:#{current_user.company_id} #{projects} #{query}", {:limit => 1000})

    # Find chat messages
    rooms = ""
    ShoutChannel.find(:all, :conditions => ["(company_id = ?) AND (project_id IS NULL OR project_id IN (#{current_project_ids}))", current_user.company_id],
                      :order => "company_id, project_id, name").each do |r|
      rooms << "|" unless rooms == ""
      rooms << "#{r.id}"
    end
    rooms = "0" if rooms == ""
    rooms = "+shout_channel_id:\"#{rooms}\" +message_type:0"
    @shouts = Shout.find_by_contents("+company_id:#{current_user.company_id} #{rooms} #{query}", {:limit => 100})


    # Find Wikis
    @wiki_pages = WikiPage.find_by_contents("+company_id:#{current_user.company_id} #{query}", {:limit => 100})


    # Find posts
    forums = ""
    Forum.find(:all, :conditions => ["(company_id = ?) AND (project_id IS NULL OR project_id IN (#{current_project_ids}))", current_user.company_id],
                      :order => "company_id, project_id, name").each do |f|
      forums << "|" unless forums == ""
      forums << "#{f.id}"
    end
    forums = "+forum_id:\"#{forums}\""
    @posts = Post.find_by_contents("+company_id:#{current_user.company_id} #{forums} #{query}", {:limit => 100})

    # Find instant messages
    chats = ""
    Chat.find(:all, :conditions => ["user_id = ?", current_user.id]).each do |c|
      chats << "|" unless chats == ""
      chats << "#{c.id}"
    end
    chats = "0" if chats == ""
    chats = "+chat_id:\"#{chats}\""
    @chat_messages = ChatMessage.find_by_contents("#{chats} #{query}", {:limit => 100})
    
  end
end
