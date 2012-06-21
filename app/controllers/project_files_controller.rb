# encoding: UTF-8
# Allow Users to upload/download files, and generate thumbnails where appropriate.
# If it's not an image, try and find an appropriate stock icon
#
class ProjectFilesController < ApplicationController

  def list
    if current_user.projects.empty?
      flash[:info] = _('Please create a project to attach files / folders to.')
      redirect_to new_project_path
      return
    end
    folder = params[:id]
    @current_folder = ProjectFolder.find_by_id(params['id']) || ProjectFolder.new( :name => "/" )
    @project_files = ProjectFile.order("created_at DESC").accessed_by(current_user).where("task_id IS NULL").where(:project_folder_id => folder.blank? ? nil : folder)
    @project_folders = ProjectFolder.order("name").where("company_id = ? AND project_id IN (?)", current_user.company_id, current_project_ids).where(:parent_id => folder.blank? ? nil : folder)

    unless folder.blank?
      up = ProjectFolder.new
      up.name = ".."
      up.created_at = Time.now.utc
      up.id = @current_folder.parent_id
      up.project = @current_folder.project
      @project_folders = [up] + @project_folders
    end
  end

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


  def new_file
    if current_user.projects.nil? || current_user.projects.size == 0
      redirect_to new_project_path
      return
    else
      current_folder = ProjectFolder.find_by_id(params['id'])
      @file = ProjectFile.new
      @file.project_folder_id = params[:id]
      @file.project_id = current_folder.nil? ? nil : current_folder.project_id
    end
  end

  def new_folder
    if current_user.projects.nil? || current_user.projects.size == 0
      redirect_to new_project_path
      return
    else

      @parent_folder = ProjectFolder.find_by_id(params[:id])
      if params[:id].to_i > 0 && @parent_folder.nil?
        flash[:error] = _('Unable to find parent folder.')
        redirect_to project_files_list_path
        return
      end

      @folder = ProjectFolder.new
      @folder.parent_id = @parent_folder.nil? ? nil : @parent_folder.id
      @folder.project_id = @parent_folder.nil? ? nil : @parent_folder.project_id
    end
  end

  def edit_folder
    if current_user.projects.nil? || current_user.projects.size == 0
      redirect_to :controller => 'projects', :action => 'new'
    else
      @folder = ProjectFolder.where("project_id IN (?)", current_project_ids).find(params[:id])
    end
  end

  def update_folder
    @folder = ProjectFolder.where("project_id IN (?)", current_project_ids).find(params[:id])
    unless @folder.update_attributes(params[:folder])
      flash[:error] = 'Unable to update folder.'
      render :action => :edit_folder
      return
    end
    flash[:success] = "folder #{@folder.name} updated successfully."
    redirect_to :action => :list
  end

  def create_folder
    @folder = ProjectFolder.new(params[:folder])
    @folder.company_id = current_user.company_id
    if @folder.parent_id.to_i > 0
      parent = ProjectFolder.where("company_id = ? AND project_id IN (?)", current_user.company_id, current_project_ids).first
      if parent.nil?
        message = render_to_string(:partial => "/layouts/flash.html.erb", :locals => {:message => _('Unable to find selected parent folder.')})
        render :json => {:status => 'error', :message => message}
        return
      end
    end
    unless @folder.save
      flash[:error] = 'Unable to save folder.'
      render :action => :new_folder
    else
      flash[:success] = "folder #{@folder.name} created successfully."
      redirect_to :action => :list
    end
  end

  def upload
    @project_files = []
    if params['tmp_files'].blank? || params['tmp_files'].select{|f| f != ""}.size == 0
      @valid, @message = false, _('No file selected.')
      flash[:error]="No file selected."
      redirect_to :back
      return
    end
    params['tmp_files'].each_with_index do |tmp_file,idx|
      next if !tmp_file.respond_to?('original_filename') or tmp_file.original_filename.nil? or tmp_file.original_filename.strip.empty?

      project_file = ProjectFile.new
      project_file.project_id = params['file']['project_id'].to_i
      project_file.project_folder_id = params['file']['project_folder_id']
      project_file.company_id = current_user.company_id
      project_file.user_id = current_user.id
      project_file.customer_id = Project.find(project_file.project_id).customer_id
      project_file.file= tmp_file
      project_file.uri= Digest::MD5.hexdigest(tmp_file.read)
      unless project_file.save
        @valid, @message = false, _('Unable to save file.') + " [#{project_file.filename}]"
        flash[:error]="Unable to save file"
        redirect_to :back
        return
      else
        project_file.update_attribute(:file_file_name, "#{params['file_names'][idx]}#{File.extname(project_file.filename)}") unless params['file_names'].blank? || params['file_names'][idx].blank?
        @project_files << project_file
      end
    end
    flash[:success] = "Success"
    redirect_to :action => :list
  end

  def edit_file
    @file = ProjectFile.accessed_by(current_user).find(params[:id])
    render :edit
  end

  def update
    @file = ProjectFile.accessed_by(current_user).find(params[:id])
    unless @file.update_attributes(params[:file])
      flash[:error]="Unable to update file"
      render :action => :edit_file
      return
    end

    flash[:success] = "file #{@file.name} updated successfully."
    redirect_to :action => :list
  end

  def destroy_file
    @file = ProjectFile.accessed_by(current_user).find_by_id(params[:id])

    if @file.nil?
      message = render_to_string(:partial => "/layouts/flash.html.erb", :locals => {:message => _("No such file.")})
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

  def destroy_folder
    @folder = ProjectFile.accessed_by(current_user).find_by_id(params[:id])

    if @folder.nil?
      message = render_to_string(:partial => "/layouts/flash.html.erb", :locals => {:message => _("No such folder.")})
      render :json => {:status => 'error', :message => message}
      return
    end

    @folder.destroy
    render :json => {:status => 'success'}
  end

  def move
    elements = params[:id].split(' ')

    drag_id = elements[0].split('_')[2]
    drop_id = elements[1].split('_')[2]

    if elements[0].include?('folder')
      @drag = ProjectFolder.find_by_id(drag_id)

      if @drag.nil?
        render :nothing => true
        return
      end

      @drop = ProjectFolder.find_by_id(drop_id) if drop_id.to_i > 0
      if @drop.nil?
        # Moving to root
        @drag.parent_id = nil
        @folder = ProjectFolder.new(:name => "..", :project => @drag.project)
        @up = false
      else
        @drag.parent_id = (@drop.parent_id == @drag.parent_id) ? @drop.id : @drop.parent_id
        @up = @drop.id != @drag.parent_id
        @folder = @drop
      end
      @drag.save
    else

      @file = ProjectFile.find_by_id(drag_id)
      if @file.nil?
        render :nothing => true
        return
      end

      @folder = ProjectFolder.find_by_id(drop_id) if drop_id.to_i > 0
      if @folder.nil?
        # Move to root directory
        @file.project_folder_id = nil
        @folder = ProjectFolder.new(:name => "..", :project => @file.project)
        @up = false
      else
        @up = ( @file.project_folder_id.to_i > 0 && (@file.project_folder_id > 0 && @file.project_folder.parent_id == @folder.id))
        @file.project_folder_id = @folder.id
      end
      @file.save
    end
    render :partial => 'folder_cell.html.erb', :locals => { :folder => @folder, :just_dropped => true}
  end

end
