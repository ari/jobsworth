#!/usr/bin/env ruby
# encoding: UTF-8

unless FileTest.exists?("config/database.yml")
  puts "You must first create a config/database.yml according to the instructions."
  exit
end

domain = "\n"
while domain == "\n" || domain.split('.').size < 3
  puts
  puts "Enter hostname for the Jobsworth service (for example projects.mycompany.com): "
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

ENV["RAILS_ENV"] ||= "production"
rails_load_path = File.expand_path("../config/environment.rb", __FILE__)
require rails_load_path

@user = User.new
@company = Company.new

@user.name = name
@user.username = username
@user.password = password
@user.password_confirmation = password
@user.email = email
@user.time_zone = "Europe/Oslo"
@user.locale = "en_US"
@user.option_tracktime = 1
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

puts "Create default resource types..."
system("rake db:create_default_resource_types[#{@company.id}] RAILS_ENV=production")
puts "Done"

puts
puts "All done!"
puts "---------"

puts
puts "Make sure passenger and apache httpd are properly set up and a virtual host defined."
puts
puts "Access your installation from http://#{subdomain}.#{domain}"

