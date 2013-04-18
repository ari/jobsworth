# encoding: UTF-8
# Allow Users to upload/download files, and generate thumbnails where appropriate.
# If it's not an image, try and find an appropriate stock icon
#
class ProjectFilesController < ApplicationController

  def show
    @project_file = ProjectFile.accessed_by(current_user).find(params[:id])

    if @project_file.thumbnail? || @project_file.image?
      send_file @project_file.file_path, :filename => @project_file.filename, :type => @project_file.file_content_type, :disposition => 'inline'
    else
      send_file @project_file.file_path, :filename => @project_file.filename, :type => "application/octet-stream"
    end
  end

  # Show the thumbnail for a given image
  def thumbnail
    @project_file = ProjectFile.accessed_by(current_user).find(params[:id])

    if @project_file.thumbnail?
      send_file @project_file.thumbnail_path, :filename => "thumb_" + @project_file.filename, :type => @project_file.file_content_type, :disposition => 'inline'
    else
      send_file Rails.root.join("app", "assets", "images", "unknown.png"), :filename => "thumb_" + @project_file.filename, :type => "image/png", :disposition => 'inline'
    end
  end

  def download
    @project_file = ProjectFile.accessed_by(current_user).find(params[:id])
    if (@project_file.file_content_type =~ /image.*/)
      disposition = "inline"
    else
      disposition = "attachment"
    end
    send_file @project_file.file_path, :filename => @project_file.filename, :type => @project_file.file_content_type, :disposition => disposition
  end


  def destroy_file
    @file = ProjectFile.accessed_by(current_user).find_by_id(params[:id])

    if @file.nil?
      message = render_to_string(:partial => "/layouts/flash.html.erb", :locals => {:message => t('flash.alert.file_not_found')})
      return render :json => {:status => 'error', :message => message}
    end
    l = @file.event_logs.new
    l.company_id = @file.company_id
    l.project_id = @file.project_id
    l.user_id = current_user.id
    l.event_type = EventLog::FILE_DELETED
    l.title = "#{@file.name} deleted"
    l.save

    @file.destroy
    render :json => {:status => 'success' }
  end

end
