# Allow Users to upload/download files, and generate thumbnails where appropriate.
# If it's not an image, try and find an appropriate stock icon
#
class ProjectFilesController < ApplicationController

  def index
    if current_user.projects.empty?
      flash['notice'] = _('Please create a project to attach files / folders to.')
      redirect_to :controller => 'projects', :action => 'new'
      return
    end
    list
    render :action => 'list'
  end

  def list
    if current_user.projects.empty?
      flash['notice'] = _('Please create a project to attach files / folders to.')
      redirect_to :controller => 'projects', :action => 'new'
      return
    end
    folder = params[:id]
    @current_folder = ProjectFolder.find_by_id(params['id']) || ProjectFolder.new( :name => "/" )
    @project_files = ProjectFile.find(:all, :order => "created_at DESC", :conditions => ["company_id = ? AND project_id IN (#{current_project_ids}) AND task_id IS NULL AND project_folder_id #{folder.blank? ? "IS NULL" : ("= " + folder)}", current_user.company_id])
    @project_folders = ProjectFolder.find(:all, :order => "name", :conditions => ["company_id = ? AND project_id IN (#{current_project_ids}) AND parent_id #{folder.blank? ? "IS NULL" : ("= " + folder)}", current_user.company_id])

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
    @project_files = ProjectFile.find(params[:id], :conditions => ["company_id = ? AND project_id IN (#{current_project_ids})", current_user.company_id])

    if @project_files.thumbnail? || @project_files.image?
      send_file @project_files.file_path, :filename => @project_files.filename, :type => @project_files.mime_type, :disposition => 'inline'
    else
      send_file @project_files.file_path, :filename => @project_files.filename, :type => "application/octet-stream"
    end
  end

  # Show the thumbnail for a given image
  def thumbnail
    @project_files = ProjectFile.find(params[:id], :conditions => ["company_id = ? AND project_id IN (#{current_project_ids})", current_user.company_id])

    if @project_files.thumbnail?
      send_file @project_files.thumbnail_path, :filename => "thumb_" + @project_files.filename, :type => "image/jpeg", :disposition => 'inline'
    else
      send_file "#{Rails.root}/public/images/unknown.png", :filename => "thumb_" + @project_files.filename, :type => "image/png", :disposition => 'inline'
    end
  end

  def download
    @project_files = ProjectFile.find(params[:id], :conditions => ["company_id = ? AND project_id IN (#{current_project_ids})", current_user.company_id])
    if (@project_files.mime_type =~ /image.*/)
      disposition = "inline"
  else
      disposition = "attachment"
  end
    send_file @project_files.file_path, :filename => @project_files.filename, :type => @project_files.mime_type, :disposition => disposition
  end


  def new_file
    if current_user.projects.nil? || current_user.projects.size == 0
      redirect_to :controller => 'projects', :action => 'new'
    else
      current_folder = ProjectFolder.find_by_id(params['id'])
      @file = ProjectFile.new
      @file.project_folder_id = params[:id]
      @file.project_id = current_folder.nil? ? nil : current_folder.project_id
    end
    render :partial => "new_file"
  end

  def new_folder
    if current_user.projects.nil? || current_user.projects.size == 0
      redirect_to :controller => 'projects', :action => 'new'
    else

      @parent_folder = ProjectFolder.find_by_id(params[:id])
      if params[:id].to_i > 0 && @parent_folder.nil?
        flash['notice'] = _('Unable to find parent folder.')
        redirect_to :action => list
        return
      end

      @folder = ProjectFolder.new
      @folder.parent_id = @parent_folder.nil? ? nil : @parent_folder.id
      @folder.project_id = @parent_folder.nil? ? nil : @parent_folder.project_id
    end
    render :partial => "new_folder"
  end

  def edit_folder
    if current_user.projects.nil? || current_user.projects.size == 0
      redirect_to :controller => 'projects', :action => 'new'
    else
      @folder = ProjectFolder.find(params[:id], :conditions => ["project_id IN (#{current_project_ids})"])
    end
  end

  def update_folder
    @folder = ProjectFolder.find(params[:id], :conditions => ["project_id IN (#{current_project_ids})"])
    unless @folder.update_attributes(params[:folder])
      flash['notice'] = _('Unable to update folder.')
      redirect_to :action => 'list', :id => @folder.parent_id
      return
    end

  end

  def create_folder
    @folder = ProjectFolder.new(params[:folder])
    @folder.company_id = current_user.company_id
    if @folder.parent_id.to_i > 0
      parent = ProjectFolder.find(:first, :conditions => ["company_id = ? AND project_id IN (#{current_project_ids})", current_user.company_id])
      if parent.nil?
        flash['notice'] = _('Unable to find selected parent folder.')
        redirect_to :action => list
        return
      end
    end
    unless @folder.save
      render :action => 'list'
    end
  end

  def upload
    @type, @project_files = 'file', []
    if params['tmp_files'].blank? || params['tmp_files'].select{|f| f != ""}.size == 0
      @valid, @message = false, _('No file selected.')
      render :file => '/project_files/upload.json.erb' and return
    end
    params['tmp_files'].each_with_index do |tmp_file,idx|
      next if !tmp_file.respond_to?('original_filename') or tmp_file.original_filename.nil? or tmp_file.original_filename.strip.empty?

      project_file = ProjectFile.new
      project_file.project_id = params['file']['project_id'].to_i
      project_file.project_folder_id = params['file']['project_folder_id']
      project_file.company_id = current_user.company_id
      project_file.user_id = current_user.id
      project_file.name = params['file_names'][idx] unless params['file_names'].blank? || params['file_names'][idx].blank?
      project_file.customer_id = Project.find(project_file.project_id).customer_id
      project_file.file= tmp_file
      unless project_file.save
        @valid, @message = false, _('Unable to save file.') + " [#{project_file.filename}]"
        render :file => '/project_files/upload.json.erb' and return
      else
        @project_files << project_file
      end
    end
    @valid = true
    render :file => '/project_files/upload.json.erb'
  end

  def edit
    @file = ProjectFile.find(params[:id], :conditions => ["company_id = ? AND project_id IN (#{current_project_ids})", current_user.company_id])
    render :partial => "edit"
  end

  def update
    @file = ProjectFile.find(params[:id], :conditions => ["company_id = ? AND project_id IN (#{current_project_ids})", current_user.company_id])
    unless @file.update_attributes(params[:file])
      flash['notice'] = _('Unable to update file')
      redirect_to :action => 'list', :id => @file.project_folder_id
    end
    render :partial => 'file_cell.html.erb', :locals => { :project_files => @file}
  end

  def destroy
    @file = ProjectFile.find_by_id(params[:id], :conditions => ["company_id = ? AND project_id IN (#{current_project_ids})", current_user.company_id])

    if @file.nil?
      flash['notice'] = _("No such file.")
      redirect_to :action => 'list'
      return
    end
    l = @file.event_logs.new
    l.company_id = @file.company_id
    l.project_id = @file.project_id
    l.user_id = current_user.id
    l.event_type = EventLog::FILE_DELETED
    l.title = "{@file.name} deleted"
    l.save

    @file.destroy
    
    respond_to do |format|
      format.html { redirect_from_last }
      format.js { render :nothing => true }
    end

  end

  def destroy_folder
    @folder = ProjectFolder.find_by_id(params[:id], :conditions => ["company_id = ? AND project_id IN (#{current_project_ids})", current_user.company_id] )

    if @folder.nil?
      flash['notice'] = _("No such folder.")
      redirect_to :action => 'list'
      return
    end

    @folder.destroy
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

    render :nothing => true
  end
end
