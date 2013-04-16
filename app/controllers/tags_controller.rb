# encoding: UTF-8
class TagsController < ApplicationController
  cache_sweeper :tag_sweeper, :only => [:update, :destroy]

  def index
    @tags = current_user.company.tags
  end

  def edit
    @tag = current_user.company.tags.find(params[:id])

    if @tag.nil?
      flash[:error] = t('flash.alert.unauthorized_operation')
      redirect_to tags_path
    end
  end

  def update
    @tag = current_user.company.tags.find(params[:id])

    if @tag and @tag.update_attributes(params[:tag])
      flash[:success] = t('flash.notice.model_updated', model: Tag.model_name.human)
    else
      flash[:error] = t('flash.alert.unauthorized_operation')
    end

    redirect_to tags_path
  end

  def destroy
    @tag = current_user.company.tags.find(params[:id])

    if @tag
      @tag.destroy
      flash[:success] = t('flash.notice.model_deleted', model: Tag.model_name.human)
    else
      flash[:error] = t('flash.alert.unauthorized_operation')
    end

    redirect_to tags_path
  end

  def auto_complete_for_tags
    value = params[:term]

    @tags = current_user.company.tags.where('name LIKE ?', '%' + value +'%')
    render :json=> @tags.collect{|tag| {:value => tag.name }}.to_json
  end
end
