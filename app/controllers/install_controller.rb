class InstallController < ApplicationController
  layout "install"

  skip_before_filter :install, :authorize
  before_filter :check_can_install

  def index
    render :action => "one"
  end

  # Step one: create the database
  def one
	db = params[:db]
	
	db_config = []
	    
	db_config << "production:"
	db_config << "adapter: #{db[:type]}"
	db_config << "database: #{db[:name]}"
	db_config << "host: #{db[:host]}"
	db_config << "username: #{db[:username]}"
	db_config << "password: #{db[:password]}"
	db_config << "encoding: utf8"
	db_config << "SOCKET"
	  
	File.open("config/database.yml", "w") do |file|
		file.puts db_config
	end
	
	ActiveRecord::Base.establish_connection(
		:adapter  => db[:type],
		:host     => db[:host],
		:username => db[:rootuser],
		:password => db[:rootpass]
	)
	
	ActiveRecord::Base.connection.create_database(db[:name])
	ActiveRecord::Base.connection.execute("CREATE DATABASE #{db[:name]} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;")
	ActiveRecord::Base.connection.execute("GRANT ALL ON #{db[:name]}.* TO '#{db[:username]}'@'localhost' IDENTIFIED BY '#{db[:password]}';")
	ActiveRecord::Base.connection.execute("FLUSH PRIVILEGES;\" | mysql -u root -p '#{db[:password]}'")

	db_config = YAML.load_file(Rails.root.join("config/database.yml"))
	ActiveRecord::Base.establish_connection(db_config[RAILS_ENV])


	# Creating directories...
	Dir.mkdir("log") rescue nil
	Dir.mkdir("index") rescue nil
	Dir.mkdir("store") rescue nil
	Dir.mkdir("store/avatars") rescue nil
	Dir.mkdir("store/logos") rescue nil
	Dir.mkdir("tmp") rescue nil
	Dir.mkdir("tmp/cache") rescue nil
	
	
	# Initialize database schema
	system("rake db:schema:load RAILS_ENV=production")
	system("rake db:migrate RAILS_ENV=production")


	# Loading Rails to create account
	begin
	require "config/environment"
	rescue
	  puts "** Unable to load Rails, please try:"
	  puts "  ./script/console"
	  puts "and look at the error reported."
	  exit
	end

	# Running all migrations
	system("rake db:migrate RAILS_ENV=production")
	
	render :action => "two"
  end
  
  def two
    prefs = params[:pref]
    # prefs.domain
    # subdomain = domain.split('.').first
    # prefs.email_domain = prefs.replyto.split('.')[1..-1].join('.')
    # prefs.replyto = prefs.replyto.split('@').first
    # prefs.from = prefs.from.split('@').first
    
    
    
    @company = Company.new(params[:company])
    @company.subdomain = @company.name.to_s.parameterize("_")

    @user = User.new(params[:user])
    @user.admin = true
    @user.seen_welcome = true
    @user.company = @company
    @user.username = @user.name

    if @company.valid? and @user.valid?
      customer = @company.customers.build(:name => @company.name)
      @user.customer = customer

      @company.save
      @user.save

      project_params = params[:project].merge(:customer => customer)
      project = @company.projects.create!(project_params)

      perm = project.project_permissions.build(:user => @user, :company => @company)
      perm.set("all")
      perm.save!

      session[:user_id] = @user.id

      prompts_params = { 
        :name => "The name of your first task",
        :description => "A longer description of your first task",
        :project_id => project.id
      }
      redirect_to url_for(:controller => "tasks", :action => "new",
                          :task => prompts_params)
    else
      render :action => "index"
    end
  end

  private

  def check_can_install
    if Company.count > 0
      redirect_to "/tasks/list" and return false
    else
      return true
    end
  end
end
