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
    @project_files = ProjectFile.find(:all, :order => "created_at DESC", :conditions => ["company_id = ? AND project_id IN (#{current_project_ids}) AND task_id IS NULL AND project_folder_id #{folder.nil? ? "IS NULL" : ("= " + folder)}", current_user.company_id])
    @project_folders = ProjectFolder.find(:all, :order => "name", :conditions => ["company_id = ? AND project_id IN (#{current_project_ids}) AND parent_id #{folder.nil? ? "IS NULL" : ("= " + folder)}", current_user.company_id])

    unless folder.nil?
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

    if @project_files.thumbnail? || @project_files.file_type == ProjectFile::FILETYPE_IMG
#      image = Magick::Image.read(@project_files.file_path ).first
      send_file @project_files.file_path, :filename => @project_files.filename, :type => @project_files.mime_type, :disposition => 'inline'
      GC.start
    else
      send_file @project_files.file_path, :filename => @project_files.filename, :type => "application/octet-stream"
    end
  end

  # Show the thumbnail for a given image
  def thumbnail
    @project_files = ProjectFile.find(params[:id], :conditions => ["company_id = ? AND project_id IN (#{current_project_ids})", current_user.company_id])

    if @project_files.thumbnail?
#      image = Magick::Image.read( @project_files.thumbnail_path ).first
      send_file @project_files.thumbnail_path, :filename => "thumb_" + @project_files.filename, :type => "image/jpeg", :disposition => 'inline'
      GC.start
    else
      send_file "#{RAILS_ROOT}/public/images/unknown.png", :filename => "thumb_" + @project_files.filename, :type => "image/png", :disposition => 'inline'
    end
  end

  def download
    @project_files = ProjectFile.find(params[:id], :conditions => ["company_id = ? AND project_id IN (#{current_project_ids})", current_user.company_id])
    send_file @project_files.file_path, :filename => @project_files.filename, :type => "application/octet-stream"
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
    project_files = []
    if params['tmp_files'].blank? || params['tmp_files'].select{|f| f != ""}.size == 0 
      flash['notice'] = _('No file selected.')
      responds_to_parent do
        render :update do |page|
          page.visual_effect(:shake,'inline_form')
        end 
      end
      return
    end

    params['tmp_files'].each_with_index do |tmp_file,idx|
	    next unless tmp_file.respond_to?('original_filename')
      filename = tmp_file.original_filename
      next if filename.nil? || filename.strip.length == 0
      filename = filename.split("/").last
      filename = filename.split("\\").last

      filename.gsub!(/[^\w.]/, '_')

      project_file = ProjectFile.new
      project_file.project_id = params['file']['project_id'].to_i
      project_file.project_folder_id = params['file']['project_folder_id']

      project_file.company_id = current_user.company_id
      project_file.user_id = current_user.id
      project_file.filename = filename
      project_file.name = params['file_names'][idx] unless params['file_names'].blank? || params['file_names'][idx].blank?
      project_file.save
      project_file.reload
      project_file.customer_id = project_file.project.customer_id

      if !File.exist?(project_file.path) || !File.directory?(project_file.path)
        File.umask(0)
        Dir.mkdir(project_file.path, 0777) rescue begin
                                                    project_file.destroy
                                                    flash['notice'] = _('Unable to create storage directory.')
                                                    redirect_to :action => 'list', :id => params[:file][:project_folder_id]
                                                    return
                                                  end
      end
      File.umask(0)
      File.open(project_file.file_path, "wb", 0777) { |f| f.write( tmp_file.read ) } rescue begin
                                                                                              project_file.destroy
                                                                                              flash['notice'] = _("Permission denied while saving file.")
                                                                                              redirect_to :action => 'list', :id => params[:file][:project_folder_id]
                                                                                              return
                                                                                            end

      if( File.size?(project_file.file_path).to_i > 0 )
        project_file.file_size = File.size?( project_file.file_path )

        if project_file.filename[/\.gif|\.png|\.jpg|\.jpeg|\.tif|\.bmp|\.psd/i] && project_file.file_size > 0
          image = ImageOperations::get_image(project_file.file_path )
					if ImageOperations::is_image?(image)
            project_file.file_type = ProjectFile::FILETYPE_IMG
            project_file.mime_type = image.mime_type
						thumb = ImageOperations::thumbnail(image,124)

            File.umask(0)
            t = File.new(project_file.thumbnail_path, "w", 0777)
            t.write(thumb.to_blob)
            t.close
          end
        end
        GC.start
      
        project_file.file_type = file_type_from_filename(filename) if project_file.file_type != ProjectFile::FILETYPE_IMG

        unless project_file.save
          flash['notice'] = _('Unable to save file.') + " [#{project_file.filename}]"
          redirect_to :action => 'list', :id => params[:file][:project_folder_id]
        else
          project_files << project_file
        end 

      end 

    end 

    responds_to_parent do
      render :update do |page|
        if project_files.size > 0 
          page.hide('inline_form')
          project_files.each do |project_file|
            page.insert_html :after, 'dir_sep', :partial => 'file_cell',  :locals => { :project_files => project_file }
            page.visual_effect(:highlight, "file_cell_#{project_file.id}", :duration => 2.0)
          end 
        else
          page.visual_effect(:shake,'inline_form')
        end 
      end 

    end
  end

  def edit
    @file = ProjectFile.find(params[:id], :conditions => ["company_id = ? AND project_id IN (#{current_project_ids})", current_user.company_id])
  end

  def update
    @file = ProjectFile.find(params[:id], :conditions => ["company_id = ? AND project_id IN (#{current_project_ids})", current_user.company_id])
    unless @file.update_attributes(params[:file])
      flash['notice'] = _('Unable to update file')
      redirect_to :action => 'list', :id => @file.project_folder_id
    end
  end

  def destroy
    @file = ProjectFile.find_by_id(params[:id], :conditions => ["company_id = ? AND project_id IN (#{current_project_ids})", current_user.company_id])

    if @file.nil?
      flash['notice'] = _("No such file.")
      redirect_to :action => 'list'
      return
    end

    begin
      File.delete(@file.file_path)
      File.delete(@file.thumbnail_path)
    rescue
    end
    l = @file.event_logs.new
    l.company_id = @file.company_id
    l.project_id = @file.project_id
    l.user_id = current_user.id
    l.event_type = EventLog::FILE_DELETED
    l.title = "{@file.name} deleted"
    l.save

    @file.destroy

    return if request.xhr?

    redirect_from_last

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

  end


  private
  
  def file_type_from_filename(filename)
    file_types = { 
      'doc'  => ProjectFile::FILETYPE_DOC, 
      'txt'  => ProjectFile::FILETYPE_TXT,
      'xls'  => ProjectFile::FILETYPE_XLS,
      'sxc'  => ProjectFile::FILETYPE_XLS,
      'csv'  => ProjectFile::FILETYPE_XLS,
      'avi'  => ProjectFile::FILETYPE_AVI,
      'mpeg' => ProjectFile::FILETYPE_AVI,
      'mpg'  => ProjectFile::FILETYPE_AVI,
      'mov'  => ProjectFile::FILETYPE_MOV,
      'swf'  => ProjectFile::FILETYPE_SWF,
      'fla'  => ProjectFile::FILETYPE_FLA,
      'xml'  => ProjectFile::FILETYPE_XML,
      'html' => ProjectFile::FILETYPE_HTML,

      'css' => ProjectFile::FILETYPE_CSS,
      'zip' => ProjectFile::FILETYPE_ZIP,
      'rar' => ProjectFile::FILETYPE_RAR,
      'tgz' => ProjectFile::FILETYPE_TGZ,

      'mp3'  => ProjectFile::FILETYPE_AUDIO,
      'wav'  => ProjectFile::FILETYPE_AUDIO,
      'ogg'  => ProjectFile::FILETYPE_AUDIO,
      'aiff' => ProjectFile::FILETYPE_AUDIO,
      'iso'  => ProjectFile::FILETYPE_ISO,
      'sql'  => ProjectFile::FILETYPE_SQL,
      'asf'  => ProjectFile::FILETYPE_ASF,
      'wmv'  => ProjectFile::FILETYPE_WMV
    }

    _,ext = /\.([^\.]+)$/.match(filename).to_a

    file_type = file_types[ext.downcase] if ext
    file_type ||= ProjectFile::FILETYPE_UNKNOWN
    file_type
  end



end
