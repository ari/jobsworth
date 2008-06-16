namespace :textile_editor_helper do
  PLUGIN_ROOT = File.dirname(__FILE__) + '/..'
  ASSET_FILES = Dir[PLUGIN_ROOT + '/assets/**/*'].select { |e| File.file?(e) }
  
  desc 'Installs required assets'
  task :install do
    #ENV['FORCE'] = true
    #Rake::Task[:update].invoke
    #force = ENV['FORCE'] || false
    verbose = true
    ASSET_FILES.each do |file|
      path = File.dirname(file) + '/'
      path.gsub!(PLUGIN_ROOT, RAILS_ROOT)
      path.gsub!('assets', 'public')
      destination = File.join(path, File.basename(file))
      puts " * Copying %-50s to %s" % [file.gsub(PLUGIN_ROOT, ''), destination.gsub(RAILS_ROOT, '')] if verbose
      FileUtils.mkpath(path) unless File.directory?(path)
      
      #puts File.mtime(file), File.mtime(destination)
      #if force || !FileUtils.identical?(file, destination)
      FileUtils.cp [file], path
      #end  
    end    
  end
  
  desc 'Removes assets for the plugin'
  task :remove do
    ASSET_FILES.each do |file|
      path = File.dirname(file) + '/'
      path.gsub!(PLUGIN_ROOT, RAILS_ROOT)
      path.gsub!('assets', 'public')
      path = File.join(path, File.basename(file))
      puts ' * Removing %s' % path.gsub(RAILS_ROOT, '') if verbose
      FileUtils.rm [path]
    end
  end
end