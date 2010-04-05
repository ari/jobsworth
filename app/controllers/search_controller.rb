# Search across all WorkLogs and Tasks
class SearchController < ApplicationController

  def search
    @tasks = []
    @logs = []

    return if params[:query].blank?
    @keys = params[:query].split.map { |s| s.strip.downcase }

    company = current_user.company
    project_ids = "(#{ current_user.all_project_ids.join(", ") })"

    @tasks = Task.search(current_user, @keys)
    @customers = Customer.search(current_user.company, @keys)
    @users = User.search(current_user.company, @keys)

    # work logs
    conditions = Search.search_conditions_for(@keys, [ "work_logs.body" ])
    conditions += " AND project_id in #{ project_ids }"
    @logs = company.work_logs.all(:conditions => conditions)

    @wiki_pages = company.wiki_pages.select do |p| 
      match = @keys.detect { |k| p.body and p.body.index(k) }
    end

    # posts
    conditions = "project_id is null or project_id in #{ project_ids }"
    forums = company.forums.all(:conditions => conditions)
    forum_ids = forums.map { |c| c.id }.join(", ")
    if forum_ids.present?
      conditions = Search.search_conditions_for(@keys, [ "posts.body" ])
      conditions += " AND forum_id in (#{ forum_ids })"
      @posts = Post.all(:conditions => conditions)
    end

  end

end
