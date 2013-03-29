require 'cucumber/rspec/doubles'

Then /^contact creation is enabled$/ do
  puts Setting.inspect

  #Setting.stub :contact_creation_allowed => true
  Setting.contact_creation_allowed = true

  '***'

  puts Setting.inspect
end

Then /^contact creation is disabled$/ do
end