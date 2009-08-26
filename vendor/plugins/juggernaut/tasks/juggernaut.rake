desc "Install the js and swf files to correct places"
task :install_juggernaut do
  puts "Installing Juggernaut..."
  FileUtils.cp(File.dirname(__FILE__) + "/../media/juggernaut_javascript.js", RAILS_ROOT + '/public/javascripts/')
  FileUtils.cp(File.dirname(__FILE__) + "/../media/socket_server.swf", RAILS_ROOT + '/public/')
  FileUtils.cp(File.dirname(__FILE__) + "/../media/push_server", RAILS_ROOT + '/script/')
  FileUtils.cp(File.dirname(__FILE__) + "/../JUGGERNAUT-README", RAILS_ROOT)
  FileUtils.cp(File.dirname(__FILE__) + "/../media/juggernaut_config.yml", RAILS_ROOT + '/config/')
  FileUtils.cp(File.dirname(__FILE__) + "/../media/crossdomain.xml", RAILS_ROOT + '/public/')
  puts "Congrats, Juggernaut has been installed. For more info look at the JUGGERNAUT-README"
end
