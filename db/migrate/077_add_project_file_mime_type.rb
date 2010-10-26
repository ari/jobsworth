class AddProjectFileMimeType < ActiveRecord::Migration

  require 'RMagick'


  def self.up
    add_column :project_files, :mime_type, :string, :default => 'application/octet-stream'

    execute("update project_files set mime_type='application/octet-stream'")

    ProjectFile.all.each do |f|
      if f.thumbnail?
        image = Magick::Image.read(f.file_path).first
        puts "Setting mime_type=#{image.mime_type}"
        f.mime_type = image.mime_type
        f.save
      end
    end


  end

  def self.down
    remove_column :project_files, :mime_type
  end
end
