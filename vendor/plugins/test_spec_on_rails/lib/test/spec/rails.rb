require 'test/spec'

module Test::Spec::Rails
  VERSION = "0.1"
end

%w(
  test_spec_ext
  test_unit_ext
  
  test_dummy
  dummy_response
  test_status
  test_template
  test_layout
  
  should_redirect
  should_render
  should_route
  should_select
  should_validate
  should_validate_presence_of
  
  use_controller
  
).each do |file|
  require "test/spec/rails/#{file}"
end
