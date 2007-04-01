class ApiController < ApplicationController

  def login
  end

  def get_projects
    projects = Project.find(:all, :conditions => ["projects.company_id=1"], :include => [ :customer])
    render :xml => projects.to_xml(:include => [:customer, :tasks])
  end

  def get_tasklists
  end

  def get_tasks
  end
end
