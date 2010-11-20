# encoding: UTF-8
# Placeholder for the upcoming API
#
class ApiController < ApplicationController

  # Return a list of Projects
  def get_projects
    projects = Project.where("projects.company_id=1").includes(:customer)
    render :xml => projects.to_xml(:include => [:customer, :tasks])
  end

  # Return a list of Tasks for a Project
  def get_tasks
  end
end
