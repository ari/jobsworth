# Only the essential records required to run the application

def create_company
  Rails.logger.info 'Creating company'
  company = Company.create!(:subdomain=>'jobsworth', :name => 'Default Company')
end

def create_admin
  Rails.logger.info 'Creating admin'
  user = User.new(
    company: Company.first,
    name: 'admin',
    username: 'admin',
    email: 'admin@example.org',
    time_zone: 'UTC',
    option_tracktime: 1,
    date_format: '%d/%m/%Y',
    time_format: '%H:%M',
    )
  user.password = 'password'
  user.password_confirmation = 'password'
  user.admin = true
  user.save!
end

create_company
create_admin
