#!/usr/bin/env ruby

#You might want to change this
#ENV["RAILS_ENV"] ||= "development"

require File.dirname(__FILE__) + "/../config/environment"

min_cid = ARGV[0].to_i

companies = Company.find(:all, :order => "id", :conditions => ["id > ?", min_cid])

companies.each do |company|

  files = ProjectFile.find(:all, :conditions => ["company_id = ?", company.id])
  files.each do |file|
    print "[#{company.id}] [#{file.id}] #{file.filename}..."
    unless File.exist?(file.file_path)
      puts '[Missing]'
      next
    end 

    if file.filename[/\.(gif|png|pdf|ppt|eps|jpg|jpeg|bmp|psd|tiff|htm|html)$/]
      print "[Done] [#{file.thumbnail_path}]" if file.generate_thumbnail
    end 

    puts
  end 
end
