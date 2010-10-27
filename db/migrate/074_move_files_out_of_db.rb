class MoveFilesOutOfDb < ActiveRecord::Migration

  def self.up
    File.umask(0)
    store = File.join(File.dirname(__FILE__), '..', '..', 'store')
    Dir.mkdir(store,0777) rescue begin end
    files = ProjectFile.all
    files.each do |f|

      dir = File.join(store, f.company_id.to_s)
      Dir.mkdir(dir,0777) rescue begin end

      if(f.thumbnail_id.to_i > 0)
        # Save thumbnail
        s = File.new(f.thumbnail_path, "wb", 0777)
        s.write(f.thumbnail.data)
        s.close

      end

      if(f.binary_id.to_i > 0)
        # Save binary
        s = File.new(f.file_path, "wb", 0777)
        s.write(f.binary.data)
        s.close

      end
    end

    # Extract client logos

    Dir.mkdir(File.join(store, "logos"),0777) rescue begin end
    customers = Customer.where("binary_id IS NOT NULL")
    customers.each do |c|
      Dir.mkdir(File.join(store, "logos", c.company_id.to_s),0777) rescue begin end
      s = File.new(c.logo_path, "wb", 07777)
      s.write(c.binary.data)
      s.close
    end

  end

  def self.down
  end
end
