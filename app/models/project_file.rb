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

  has_one       :binary
  has_one       :thumbnail

  belongs_to    :binary
  belongs_to    :thumbnail

  after_destroy { |r|
    File.delete(r.path) rescue begin end
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

  def thumbnail_path
    File.join(path, "thumb_" + self.store_name)
  end

  def thumbnail?
    File.exist?(thumbnail_path)
  end

end
