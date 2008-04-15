module Test::Spec::Rails
  VERSION = "0.1"
end

require 'test/spec'

%w(
  test_spec_ext
  test_unit_ext
  
  test_dummy
  dummy_response
  test_status
  test_template
  test_layout
  
  should_redirect
  should_route
  should_select
  should_validate
  
  use_controller
  
).each do |file|
  require "test/spec/rails/#{file}"
end
