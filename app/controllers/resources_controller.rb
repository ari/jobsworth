class ResourcesController < ApplicationController
  
  def index
    @resources = current_user.company.resources
  end

  def new
  end

  def create
  end

  def edit
  end

  def update
  end

  def destroy
  end
end
