#!/usr/bin/env ruby

begin
  require 'rubygems'
rescue LoadError
  puts "Please install the latest version of RubyGems to get started."
  exit
end

missing_dep = false
missing_deps = []

deps = { 'tzinfo' => 'tzinfo', 'redcloth' => 'RedCloth', 'rake' => 'rake', 'ferret' => 'ferret', 
  'fastercsv' => 'fastercsv', 'eventmachine' => 'eventmachine',  'RMagick' => 'rmagick', 
  'icalendar' => 'icalendar', 'mongrel' => 'mongrel', 'zentest' => 'ZenTest', 'hoe' => 'hoe',
  'google_chart' => 'gchartrb', 'json' => 'json', 'test/spec' => 'test-spec', 'echoe' => 'echoe'
}

puts "Verifying dependencies..."

deps.keys.each do |dep|
  begin
    require dep
  rescue LoadError
    missing_deps << deps[dep]
  end 
end 

if missing_deps.size > 0
  puts "Please install required Ruby Gems:"
  puts "  sudo gem install #{missing_deps.join(" ")} -r"
  puts
  if missing_deps.include? "rmagick"
    puts "rmagick requires ImageMagick. If you're unable to install ImageMagick 6.3.0+, which the latest"
    puts "version of rmagick requires, please install version 1.5.14 instead: "
    puts "  sudo gem install rmagick -v 1.5.14 -r"
  end
  
  exit
end

puts "Dependencies verified..."
puts

puts "*******************************************************************************************"
puts "This setup script will overwrite any configuration files you've already created in config/*"
puts "If you don't want this to happen, please press <Ctrl-c> to abort."
puts "*******************************************************************************************"
puts

print "Enter MySQL database name for ClockingIT [cit]: "
db = gets 
db = "cit" if db == "\n"
print "Enter username for ClockingIT MySQL account [cit]: "
dbuser = gets 
dbuser = "cit" if dbuser == "\n"
print "Enter password for ClockingIT MySQL account [cit]: "
dbpw = gets 
dbpw = "cit" if dbpw == "\n"

db.strip!
dbuser.strip!
dbpw.strip!

puts
puts "Using '#{dbuser}' / '#{dbpw}' to access the '#{db}' database."
puts



puts "Please create the database and user for ClockingIT by running something like this: "
puts " echo \"CREATE DATABASE #{db} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci; GRANT ALL ON #{db}.* TO '#{dbuser}'@'localhost' IDENTIFIED BY '#{dbpw}'; FLUSH PRIVILEGES;\" | mysql -u root -p "
puts 
puts "Press <Return> to continue"
gets
puts 

domain = "\n"
while domain == "\n" || domain.split('.').size < 3
  puts
  print "Enter domain ClockingIT will be accessed from (for example projects.mycompany.com): "
  domain = gets
end

domain.strip!

subdomain = domain.split('.').first
domain = domain.split('.')[1..-1].join('.')

puts
puts "Using '#{subdomain}.#{domain}' to access ClockingIT."
puts

company = "\n"

while company == "\n"
print "Enter name of initial company: "
  company = gets
end

name = "\n"
while name == "\n"
print "Enter name of initial user: "
  name = gets
end

username = "\n"
while username == "\n"
print "Enter username for initial user: "
  username = gets
end

password = "\n"
password2 = "\n"

while password != password2 || password == "\n"
  
password = "\n"
password2 = "\n"

  while password == "\n" 
    print "Enter password for initial user: "
    password = gets
  end

  while password2 == "\n"
    print "Enter password (again) for initial user: "
    password2 = gets
  end

  password.strip!
  password2.strip!
end

email = "\n"
while email == "\n"
print "Enter email address of initial user: "
  email = gets
end

company.strip!
name.strip!
username.strip!
password.strip!
email.strip!

puts 
puts "Will create '#{username}' with password '#{password}' for '#{company}' as initial administrator account."
puts 


jug_port = "\n"

print "Enter port for push server [443]: "
jug_port = gets

jug_port = "443" if jug_port == "\n"
jug_port.strip!

puts "Creating config files..."
puts "  Creating config/database.yml"

socket = %x[mysql_config --socket]
socket.strip!

db_config = []
File.open("config/database.yml-example") do |file|
  while line = file.gets
    db_config << line
  end
end
db_config = db_config.join

db_config.gsub!(/DATABASE/, db)
db_config.gsub!(/USERNAME/, dbuser)
db_config.gsub!(/PASSWORD/, dbpw)
db_config.gsub!(/SOCKET/, (socket.include?('/') ? "socket: #{socket}" : "") )

File.open("config/database.yml", "w") do |file|
  file.puts db_config
end

puts "  Creating config/environment.rb"

env = []
File.open("config/environment.rb-example") do |file|
  while line = file.gets
    env << line
  end
end
env = env.join

env.gsub!(/clockingit\.com/, domain)

File.open("config/environment.rb", "w") do |file|
  file.puts env
end

puts "  Creating config/juggernaut_config.yml"

jug = []
File.open("config/juggernaut_config.yml-example") do |file|
  while line = file.gets
    jug << line
  end
end
jug = jug.join

jug.gsub!(/clockingit\.com/, domain)
jug.gsub!(/www\./, subdomain + ".")
jug.gsub!(/443/, jug_port)

File.open("config/juggernaut_config.yml", "w") do |file|
  file.puts jug
end

puts "  Creating config/ferret_server.yml"
system("cp config/ferret_server.yml-example config/ferret_server.yml")
puts

puts "Creating directories..."

puts "  log..."
Dir.mkdir("log") rescue nil
puts "  index..."
Dir.mkdir("index") rescue nil
puts "  store..."
Dir.mkdir("store") rescue nil
puts "  store/avatars..."
Dir.mkdir("store/avatars") rescue nil
puts "  store/logos..."
Dir.mkdir("store/logos") rescue nil

puts
print "Initialize database schema [n]: "
init_db = gets
init_db = "n" if init_db == "\n"

if init_db.include?('y') || init_db.include?('Y')
  puts "Initializing database schema"
  system("rake db:schema:load RAILS_ENV=production")
  system("rake db:migrate RAILS_ENV=production")
end

puts 
puts "Loading Rails to create account..."
begin
require "config/environment"
rescue
  puts "** Unable to load Rails, please try:"
  puts "  ./script/console"
  puts "and look at the error reported."
  exit
end 



@user = User.new
@company = Company.new

@user.name = name
@user.username = username
@user.password = password
@user.email = email
@user.time_zone = "Europe/Oslo"
@user.locale = "en_US"
@user.option_externalclients = 1
@user.option_tracktime = 1
@user.option_tooltips = 1
@user.date_format = "%d/%m/%Y"
@user.time_format = "%H:%M"
@user.admin = 1

puts "  Creating initial company..."

@company.name = company
@company.contact_email = email
@company.contact_name = name
@company.subdomain = subdomain.downcase

if @company.save
  @customer = Customer.new
  @customer.name = @company.name
  
  @company.customers << @customer
  puts "  Creating initial user..."
  @company.users << @user
else 
  c = Company.find_by_subdomain(subdomain)
  if c
    puts "** Unable to create initial company, #{subdomain} already registered.. **"
    
    del = "\n"
    print "Delete existing company '#{c.name}' with subdomain '#{subdomain}' and try again? [y]: "
    del = gets
    del = "y" if del == "\n"
    del.strip!
    if del.downcase.include?('y')
      c.destroy
      if @company.save
        @customer = Customer.new
        @customer.name = @company.name
  
        @company.customers << @customer
        puts "  Creating initial user..."
        @company.users << @user
      
      else
        puts " Still unable to create initial company. Check database settings..."
        exit
      end
    end

  else 
    exit
  end
end 

puts "Creating merged CSS and JavaScript files..."
system("rake asset:packager:build_all")
puts "Done"

puts "Running any pending migrations..."
system("rake db:migrate RAILS_ENV=production")
puts "Done"

puts 
puts "All done!"
puts "---------"

puts
puts "Please start the required services by entering the following in a console:"
puts "  ./script/ferret_server -e production start"
puts "  nohup ./script/push_server &"
puts "  ./script/server production"
puts 
puts "Access your installation from http://#{subdomain}.#{domain}:3000"

