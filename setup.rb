#!/usr/bin/env ruby
# encoding: UTF-8

puts "*******************************************************************************************"
puts "This setup script will overwrite any configuration files you've already created in config/*"
puts "If you don't want this to happen, please press <Ctrl-c> to abort."
puts "*******************************************************************************************"
puts

print "Enter MySQL database name for Jobsworth [jobsworth]: "
db = gets
db = "jobsworth" if db == "\n"
print "Enter username for Jobsworth MySQL account [jobsworth]: "
dbuser = gets
dbuser = "jobsworth" if dbuser == "\n"
print "Enter password for Jobsworth MySQL account [changeme]: "
dbpw = gets
dbpw = "changeme" if dbpw == "\n"
print "Enter host for Jobsworth MySQL account [localhost]: "
dbhost = gets
dbhost = "localhost" if dbhost == "\n"

db.strip!
dbuser.strip!
dbpw.strip!
dbhost.strip!

puts
puts "Using '#{dbuser}' / '#{dbpw}' to access the '#{db}' database on '#{dbhost}'."
puts



puts "Please create the database and user for Jobsworth by running something like this: "
puts " echo \"CREATE DATABASE #{db} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci; GRANT ALL ON #{db}.* TO '#{dbuser}'@'localhost' IDENTIFIED BY '#{dbpw}'; FLUSH PRIVILEGES;\" | mysql -u root -p "
puts
puts "Press <Return> once you have done this."
gets
puts

domain = "\n"
while domain == "\n" || domain.split('.').size < 3
  puts
  print "Enter hostname for the Jobsworth service (for example projects.mycompany.com): "
  domain = gets
end

domain.strip!

subdomain = domain.split('.').first
domain = domain.split('.')[1..-1].join('.')

puts
puts "Using '#{subdomain}.#{domain}' to access Jobsworth."
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
db_config.gsub!(/HOST/, dbhost)
db_config.gsub!(/SOCKET/, (socket.include?('/') ? "socket: #{socket}" : "") )

File.open("config/database.yml", "w") do |file|
  file.puts db_config
end

puts "Creating config/environment.local.rb"

env = []
File.open("config/environment.local.example") do |file|
  while line = file.gets
    env << line
  end
end
env = env.join

env.gsub!(/getjobsworth\.org/, domain)

File.open("config/environment.local.rb", "w") do |file|
  file.puts env
end

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
puts "  tmp..."
Dir.mkdir("tmp") rescue nil
puts "  tmp/cache..."
Dir.mkdir("tmp/cache") rescue nil

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
  require File.expand_path('../config/environment', __FILE__)
rescue
  puts "*** Unable to load Rails, please ensure you have a working Rails environment. ***"
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
  @user.customer=@customer
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

puts "Running any pending migrations..."
system("rake db:migrate RAILS_ENV=production")
puts "Done"

puts
puts "All done!"
puts "---------"

puts
puts "Make sure passenger and apache httpd are properly set up and a virtual host defined."
puts
puts "Access your installation from http://#{subdomain}.#{domain}"

