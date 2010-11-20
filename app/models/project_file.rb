# encoding: UTF-8
# A file attached to a project.
#
# Possibly belongs to a task (attachment), or a ProjectFolder

class ProjectFile < ActiveRecord::Base
  has_attached_file :file, :whiny => false , :styles=>{ :thumbnail=>"124x124"}, :path => File.join("#{Rails.root.to_s}", 'store') + "/:id_:basename_:style.:extension"
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
  before_post_process :image?
  def image?
     ! file_file_name[/\.gif|\.png|\.jpg|\.jpeg|\.tif|\.bmp|\.psd/i].nil?
  end

  def file_path
    file.path
  end
  def file_size
    file.size
  end

  def filename
    self.file_file_name
  end

  # The thumbnails are jpg's even though they keep
  # their original extension.
  def thumbnail_path
    file.path(:thumbnail)
  end

  def thumbnail?
    File.exist?(self.thumbnail_path)
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
  def mime_type
    self.file_content_type
  end

  # Lookup, guesstimate if fail, the file extension
  # For example:
  # 'text/rss+xml' => "xml"
  def file_extension
      set = Mime::LOOKUP[self.mime_type]
      sym = set.instance_variable_get("@symbol") if set
      return sym.to_s if sym
      return $1 if self.mime_type =~ /(\w+)$/
      return "stream"
  end

  def generate_thumbnail(size = 124)
# %x[convert #{self.file_path}  -thumbnail "124x124" \\( +clone -background \\\#222222 -shadow 60x4+4+4 \\) +swap -background \\\#fafafa -layers merge +repage /tmp/thumb.jpg; mv /tmp/thumb.jpg #{self.thumbnail_path}]
    file.reprocess!
  end

end



# == Schema Information
#
# Table name: project_files
#
#  id                :integer(4)      not null, primary key
#  company_id        :integer(4)      default(0), not null
#  project_id        :integer(4)      default(0), not null
#  customer_id       :integer(4)      default(0), not null
#  name              :string(200)     default(""), not null
#  file_type         :integer(4)      default(0), not null
#  created_at        :datetime        not null
#  updated_at        :datetime        not null
#  filename          :string(200)     default(""), not null
#  thumbnail_id      :integer(4)
#  file_size         :integer(4)
#  task_id           :integer(4)
#  mime_type         :string(255)     default("application/octet-stream")
#  project_folder_id :integer(4)
#  user_id           :integer(4)
#
# Indexes
#
#  project_files_company_id_index            (company_id)
#  index_project_files_on_project_folder_id  (project_folder_id)
#  index_project_files_on_task_id            (task_id)
#  fk_project_files_user_id                  (user_id)
#  fk_project_files_customer_id              (customer_id)
#

