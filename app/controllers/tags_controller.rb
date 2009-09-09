class TagsController < ApplicationController
  def index
    @tags = current_user.company.tags
  end

  def edit
    @tag = current_user.company.tags.find(params[:id])

    if @tag.nil?
      flash[:notice] = _("You don't have access to edit that tag")
      redirect_to tags_path and return
    end
  end

  def update
    @tag = current_user.company.tags.find(params[:id])
    
    if @tag and @tag.update_attributes(params[:tag])
      flash[:notice] = _("Tag saved")
    else
      flash[:notice] = _("You don't have access to edit that tag")
    end

    redirect_to tags_path
  end

  def destroy
    @tag = current_user.company.tags.find(params[:id])
    
    if @tag
      @tag.destroy
      flash[:notice] = _("Tag deleted")
    else
      flash[:notice] = _("You don't have access to delete that tag")
    end

    redirect_to tags_path
  end

end
