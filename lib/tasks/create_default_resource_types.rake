def create_resource_type(company)
  ########### web service ############
  web_service = ResourceType.new(:name => "Web Service", :company_id => company.id)

  url = ResourceTypeAttribute.new({
    :name => "URL",
    :is_mandatory => true,
    :allows_multiple => false,
    :is_password => false,
  })
  web_service.resource_type_attributes << url

  user_name = ResourceTypeAttribute.new({
    :name => "User Name",
    :is_mandatory => true,
    :allows_multiple => false,
    :is_password => false,
  })
  web_service.resource_type_attributes << user_name

  password = ResourceTypeAttribute.new({
    :name => "Password",
    :is_mandatory => true,
    :allows_multiple => false,
    :is_password => true,
  })
  web_service.resource_type_attributes << password

  if ResourceType.find_by_name("Web Service")
    puts "WARNING: Resource type Web Service already exists."
  else
    web_service.save!
    puts "Resource type Web Service created."
  end

  ########### Computer ############
  computer = ResourceType.new(:name => "Computer", :company_id => company.id)
  ip = ResourceTypeAttribute.new({
    :name => "IP address",
    :is_mandatory => true,
    :allows_multiple => true,
    :is_password => false,
  })
  computer.resource_type_attributes << ip

  if ResourceType.find_by_name("Computer")
    puts "WARNING: Resource type Computer already exists."
  else
    computer.save!
    puts "Resource type Computer created."
  end

  ########### Vehicle ############
  vehicle = ResourceType.new(:name => "Vehicle", :company_id => company.id)
  license_plate = ResourceTypeAttribute.new({
    :name => "License plate",
    :is_mandatory => true,
    :allows_multiple => false,
    :is_password => false,
  })
  vehicle.resource_type_attributes << license_plate

  engine_size = ResourceTypeAttribute.new({
    :name => "Engine size",
    :is_mandatory => false,
    :allows_multiple => false,
    :is_password => false,
  })
  vehicle.resource_type_attributes << engine_size

  if ResourceType.find_by_name("Vehicle")
    puts "WARNING: Resource type Vehicle already exists."
  else
    vehicle.save!
    puts "Resource type Vehicle created."
  end
end

namespace :db do
  desc 'create default resource types'
  task :create_default_resource_types, [:company_id] => :environment  do |t, args|
    company = Company.find(args.company_id)
    puts "Creating default resource types for #{company.name}"
    if company.resource_types.size > 0
      puts "Skipped. Resource types are already defined for #{company.name}"
    else
      create_resource_type(company)
    end
  end
end
