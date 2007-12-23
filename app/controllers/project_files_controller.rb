# Allow Users to upload/download files, and generate thumbnails where appropriate.
# If it's not an image, try and find an appropriate stock icon
#
class ProjectFilesController < ApplicationController
  require_dependency 'RMagick'
#  enable_upload_progress
#  upload_status_for :upload

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

    if @project_files.thumbnail?
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
    if params['file'].nil? || params['file']['tmp_file'].nil? || !params['file']['tmp_file'].respond_to?('original_filename')
      flash['notice'] = _('No file selected.')
      redirect_from_last
      return
    end
    filename = params['file']['tmp_file'].original_filename if params['file']

    if filename.nil? || filename.strip.length == 0
      flash['notice'] = _('No file selected for upload.')
      redirect_to :action => 'list', :id => params[:file][:project_folder_id]
      return
    end


    filename = filename.split("/").last
    filename = filename.split("\\").last

    params['file']['filename'] = filename.gsub(/[^a-zA-Z0-9.]/, '_')

    tmp_file = params['file']['tmp_file']

    params['file'].delete('tmp_file')

    @project_files = ProjectFile.new(params[:file])

    @project_files.company_id = current_user.company_id
    @project_files.customer_id = @project_files.project.customer_id
    @project_files.user_id = current_user.id

    @project_files.save
    @project_files.reload

    if !File.exist?(@project_files.path) || !File.directory?(@project_files.path)
      File.umask(0)
      Dir.mkdir(@project_files.path, 0777) rescue begin
                                                    @project_files.destroy
                                                    flash['notice'] = _('Unable to create storage directory.')
                                                    redirect_to :action => 'list', :id => params[:file][:project_folder_id]
                                                    return
                                                  end
    end
    File.umask(0)
    File.open(@project_files.file_path, "wb", 0777) { |f| f.write( tmp_file.read ) } rescue begin
                                                                                              @project_files.destroy
                                                                                              flash['notice'] = _("Permission denied while saving file.")
                                                                                              redirect_to :action => 'list', :id => params[:file][:project_folder_id]
                                                                                              return
                                                                                            end


    if( File.size?(@project_files.file_path).to_i > 0 )
      @project_files.file_size = File.size?( @project_files.file_path )

      if @project_files.filename[/\.gif|\.png|\.jpg|\.jpeg|\.tif|\.bmp|\.psd/i] && @project_files.file_size > 0
        image = Magick::Image.read( @project_files.file_path ).first

        if image.columns > 0
          @project_files.file_type = ProjectFile::FILETYPE_IMG
          @project_files.mime_type = image.mime_type

          if image.columns > 124 or image.rows > 124

            if image.columns > image.rows
              scale = 124.0 / image.columns
            else
              scale = 124.0 / image.rows
            end

            image.scale!(scale)
          end

          thumb = shadow(image)
          thumb.format = 'jpg'

          File.umask(0)
          t = File.new(@project_files.thumbnail_path, "w", 0777)
          t.write(thumb.to_blob)
          t.close
        end
      end
      GC.start

      if @project_files.file_type != ProjectFile::FILETYPE_IMG
        if @project_files.filename[/\.doc/i]
          @project_files.file_type = ProjectFile::FILETYPE_DOC
        elsif @project_files.filename[/\.txt/i]
          @project_files.file_type = ProjectFile::FILETYPE_TXT
        elsif @project_files.filename[/\.xls|\.sxc|\.csv/i]
          @project_files.file_type = ProjectFile::FILETYPE_XLS
        elsif @project_files.filename[/\.avi|\.mpeg/i]
          @project_files.file_type = ProjectFile::FILETYPE_AVI
        elsif @project_files.filename[/\.mov/i]
          @project_files.file_type = ProjectFile::FILETYPE_MOV
        elsif @project_files.filename[/\.swf/i]
          @project_files.file_type = ProjectFile::FILETYPE_SWF
        elsif @project_files.filename[/\.fla/i]
          @project_files.file_type = ProjectFile::FILETYPE_FLA
        elsif @project_files.filename[/\.xml/i]
          @project_files.file_type = ProjectFile::FILETYPE_XML
        elsif @project_files.filename[/\.html/i]
          @project_files.file_type = ProjectFile::FILETYPE_HTML
        elsif @project_files.filename[/\.css/i]
          @project_files.file_type = ProjectFile::FILETYPE_CSS
        elsif @project_files.filename[/\.zip/i]
          @project_files.file_type = ProjectFile::FILETYPE_ZIP
        elsif @project_files.filename[/\.rar/i]
          @project_files.file_type = ProjectFile::FILETYPE_RAR
        elsif @project_files.filename[/\.tgz/i]
          @project_files.file_type = ProjectFile::FILETYPE_TGZ
        elsif @project_files.filename[/\.mp3|\.wav|\.ogg|\.aiff/i]
          @project_files.file_type = ProjectFile::FILETYPE_AUDIO
        elsif @project_files.filename[/\.iso|\.img/i]
          @project_files.file_type = ProjectFile::FILETYPE_ISO
        elsif @project_files.filename[/\.sql/i]
          @project_files.file_type = ProjectFile::FILETYPE_SQL
        elsif @project_files.filename[/\.asf/i]
          @project_files.file_type = ProjectFile::FILETYPE_ASF
        elsif @project_files.filename[/\.wmv/i]
          @project_files.file_type = ProjectFile::FILETYPE_WMV
        else
          @project_files.file_type = ProjectFile::FILETYPE_UNKNOWN
        end
      end

      unless @project_files.save
        flash['notice'] = _('Unable to save file.')
        redirect_to :action => 'list', :id => params[:file][:project_folder_id]
      else
        responds_to_parent do
          render :update do |page|
            page.hide('inline_form')
            page.insert_html :after, 'dir_sep', :partial => 'file_cell',  :locals => { :project_files => @project_files }
            page.visual_effect(:highlight, "file_cell_#{@project_files.id}", :duration => 2.0)
          end
        end
      end

    else
      flash['notice'] = _('Empty file.')
      @project_files.destroy
      redirect_to :action => 'list', :id => params[:file][:project_folder_id]
      return
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

  def shadow( image )
    w = image.columns
    h = image.rows

    x2 = w + 5
    y2 = h + 5

    # blur margin
    x4 = w + 15
    y4 = h + 15

    c = "White"
    base = Magick::Image.new( x4, y4 ) { self.background_color = c }

    gc = Magick::Draw.new
    gc.fill( "Gray75" )
    gc.rectangle( 5, 5, x2, y2 )
    gc.draw( base )

    # requires RMagick 1.6.1 or later.
    base = base.gaussian_blur_channel( 2, 8, Magick::AllChannels )
    base = base.gaussian_blur_channel( 3, 8, Magick::AllChannels )

    base.composite( image, Magick::NorthWestGravity, Magick::OverCompositeOp )

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


end
