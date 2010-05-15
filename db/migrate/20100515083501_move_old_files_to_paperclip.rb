class MoveOldFilesToPaperclip < ActiveRecord::Migration
  def self.up
    ProjectFile.all.each do |file|
      filename=file.attributes['filename']
      store_name =  "#{file.id}#{"_" + file.task_id.to_s if file.task_id.to_i > 0}_#{filename}"
      full_name= File.join("#{RAILS_ROOT}", 'store', file.company_id.to_s, store_name)
      if File.exist?(full_name)
        file.file= File.new(full_name)
        file.save!
      end
    end
  end

  def self.down
  end
end
