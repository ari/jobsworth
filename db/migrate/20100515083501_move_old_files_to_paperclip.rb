class MoveOldFilesToPaperclip < ActiveRecord::Migration
  def self.up
    ProjectFile.all.each do |file|
      filename=file.attributes['filename']
      store_name =  "#{file.id}#{"_" + file.task_id.to_s if file.task_id.to_i > 0}_#{filename}"
      full_name= Rails.root.join('store', file.company_id.to_s, store_name)
      if File.exist?(full_name)
        begin
          file.file= File.new(full_name)
          file.save!
        rescue Exception => e
          str= "\nCall to parerclip raise an exception\n"
          str<< "ProjectFile object inspect:\n"
          str<< file.inspect
          str<< "\nFile: #{full_name}\n"
          str<< "Paperclip.options hash:\n"
          str<< Paperclip.options.inspect
          raise e, e.message + str
        end
      end
    end
  end

  def self.down
  end
end
