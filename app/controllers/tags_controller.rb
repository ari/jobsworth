# encoding: UTF-8
class TagsController < ApplicationController
  cache_sweeper :tag_sweeper, :only => [:update, :destroy]

  def index
    @tags = current_user.company.tags
  end

  def edit
    @tag = current_user.company.tags.find(params[:id])

    if @tag.nil?
      flash[:error] = _("You don't have access to edit that tag")
      redirect_to tags_path
    end
  end

  def update
    @tag = current_user.company.tags.find(params[:id])

    if @tag and @tag.update_attributes(params[:tag])
      flash[:success] = _("Tag saved")
    else
      flash[:error] = _("You don't have access to edit that tag")
    end

    redirect_to tags_path
  end

  def destroy
    @tag = current_user.company.tags.find(params[:id])

    if @tag
      @tag.destroy
      flash[:success] = _("Tag deleted")
    else
      flash[:error] = _("You don't have access to delete that tag")
    end

    redirect_to tags_path
  end
  
  def auto_complete_for_tags
    value = params[:term]
   
    @tags = current_user.company.tags.where('name LIKE ?', '%' + value +'%')
    render :json=> @tags.collect{|tag| {:value => tag.name }}.to_json
  end
end
