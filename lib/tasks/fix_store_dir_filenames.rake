def close_store_dir
  @dir.close if @dir
end

def fix_file_name(filename, file_hash)
  filename_trailer = filename[/((_original|_thumbnail)(\.\w+)*)$/]    
  old_filename = get_file_path_for(filename)
  new_filename = get_file_path_for("#{file_hash}#{filename_trailer}")
  File.rename(old_filename, new_filename) if old_filename != new_filename
end

def fix_file_uri(filename, file_hash)
  file_extension  = File.extname(filename)
  wrong_uri       = filename.gsub(/(_original|_thumbnail)/, '')
  project_file    = ProjectFile.find_by_uri(wrong_uri)
  project_file.update_attributes(:uri => file_hash) unless project_file.nil?
end

def get_file_path_for(filename)
  "#{store_dir.path}/#{filename}"
end

def get_hash_for(filename)
  file_path = get_file_path_for(filename)
  file_data = File.read(file_path)
  Digest::MD5.hexdigest(file_data)
end

def is_a_picture?(filename)
  file_extension = File.extname(filename)
  picture_extensions = %q{.jpg .jpeg .png .gif .bmp .tiff}
  picture_extensions.include?(file_extension)
end

def picture_exist?(filename)
  file_path = get_file_path_for(filename)
  File.exist?(file_path)
end

def store_dir
  store_dir_path = "#{Rails.root}/store"
  @dir ||= Dir.new(store_dir_path) 
end

def store_dir_filenames
  store_dir.entries.delete_if { |filename| filename =~ /^\.$|^\.\.$/ }
end

def fix_picture(filename)
  picture_original = filename.gsub(/_thumbnail/, '_original')
  return unless picture_exist?(picture_original)
  file_hash = get_hash_for(picture_original)
  fix_file_uri(picture_original, file_hash)
  fix_file_name(picture_original, file_hash)
  fix_file_name(filename, file_hash) if filename =~ /_thumbnail/
end

def fix_file(filename)
  file_hash = get_hash_for(filename)
  fix_file_uri(filename, file_hash)
  fix_file_name(filename, file_hash)
end

namespace :store_dir do
  desc 'Rename the files under store/ based on the MD5 of their content'
  task :rename_files => :environment do

    store_dir_filenames.each do |filename|
      is_a_picture?(filename) ? fix_picture(filename) : fix_file(filename)
    end

    close_store_dir
  end
end
