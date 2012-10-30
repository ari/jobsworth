#!/usr/bin/env ruby

require 'rake'
require 'rake/tasklib'

RDoc::Task.new do |rd|

  rd.main = "README.rdoc"

  rd.rdoc_dir = "doc/app"

  rd.rdoc_files.include(  
    "README.rdoc",
    "NOTICE",
    "LICENSE",
    "RELEASE-NOTES",
    "app/**/*.rb",
    "lib/**/*.rb")

  rd.title = "Jobsworth"
  rd.options << '--all' # all methods, not just public
end
