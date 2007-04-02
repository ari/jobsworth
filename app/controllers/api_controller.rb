# Placeholder for the upcoming API for ClockingIT
# Author:: Erlend Simonsen (mailto:admin@clockingit.com)
class ApiController < ApplicationController

  # Return a list of Projects
  def get_projects
    projects = Project.find(:all, :conditions => ["projects.company_id=1"], :include => [ :customer])
    render :xml => projects.to_xml(:include => [:customer, :tasks])
  end

  # Return a list of Tasks for a Project
  def get_tasks
  end
end
