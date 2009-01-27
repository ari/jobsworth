# A file attached to a project.
#
# Possibly belongs to a task (attachment), or a ProjectFolder

class ProjectFile < ActiveRecord::Base

  FILETYPE_IMG          = 1

  FILETYPE_DOC          = 5
  FILETYPE_SWF          = 6
  FILETYPE_FLA          = 7
  FILETYPE_XML          = 8
  FILETYPE_HTML         = 9

  FILETYPE_ZIP          = 10
  FILETYPE_RAR          = 11
  FILETYPE_TGZ          = 12

  FILETYPE_MOV          = 13
  FILETYPE_AVI          = 14

  FILETYPE_TXT          = 16
  FILETYPE_XLS          = 17

  FILETYPE_AUDIO        = 18

  FILETYPE_ISO          = 19
  FILETYPE_CSS          = 20
  FILETYPE_SQL          = 21

  FILETYPE_ASF          = 22
  FILETYPE_WMV          = 23

  FILETYPE_UNKNOWN      = 99

  belongs_to    :project
  belongs_to    :company
  belongs_to    :customer
  belongs_to    :user
  belongs_to    :task

  belongs_to    :project_folder

  has_many   :event_logs, :as => :target, :dependent => :destroy

  after_create { |r|
    l = r.event_logs.new
    l.company_id = r.company_id
    l.project_id = r.project_id
    l.user_id = r.user_id
    l.event_type = EventLog::FILE_UPLOADED
    l.created_at = r.created_at
    l.save
  }

  after_destroy { |r|
    File.delete(r.file_path) rescue begin end
    File.delete(r.thumbnail_path) rescue begin end
  }

  def path
    File.join("#{RAILS_ROOT}", 'store', self.company_id.to_s)
  end

  def store_name
    "#{self.id}#{"_" + self.task_id.to_s if self.task_id.to_i > 0}_#{self.filename}"
  end

  def file_path
    File.join(self.path, self.store_name)
  end

  # The thumbnails are jpg's even though they keep
  # their original extension.
  def thumbnail_path
    File.join(path, "thumb_" + self.store_name)
  end

  def thumbnail?
    File.exist?(thumbnail_path)
  end

  def name
    @attributes['name'].blank? ? filename : @attributes['name']
  end

  def full_name
    if project_folder
      "#{project_folder.full_path}/#{name}"
    else
      "/#{name}"
    end
  end

  def started_at
    self.created_at
  end

  def generate_thumbnail(size = 124)
    image = ImageOperations::get_image( self.file_path ) rescue begin
                                                                  return false
                                                                  end 
    if ImageOperations::is_image?(image)
      # Call ImageMagick from the shell, as RMagick/ImageMagick runs out of memory
      # very fast. 
      res = %x[convert #{self.file_path}  -thumbnail "124x124" \\( +clone -background \\\#222222 -shadow 60x4+4+4 \\) +swap -background \\\#fafafa -layers merge +repage /tmp/thumb.jpg; mv /tmp/thumb.jpg #{self.thumbnail_path}]
      puts res

#      thumb = ImageOperations::thumbnail(image, size)
#      f = File.new(self.thumbnail_path, "w", 0777)
#      f.write(thumb.to_blob)
#      f.close
    end
    image = thumb = nil
    GC.start
    true
  end 
  
end
