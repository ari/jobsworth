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

  web_service.save!

  ########### Computer ############
  computer = ResourceType.new(:name => "Computer", :company_id => company.id)
  ip = ResourceTypeAttribute.new({
    :name => "IP address",
    :is_mandatory => true,
    :allows_multiple => true,
    :is_password => false,
  })
  computer.resource_type_attributes << ip
  computer.save!

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
  vehicle.save!
end

namespace :db do
  desc 'create default resource types'
  task :create_default_resource_types => :environment do
    Company.all.each do |company|
      puts "Start creating default resource types for #{company.name}"
      create_resource_type(company)
      puts "Creating resource types for #{company.name} succeeded."
    end
  end
end
