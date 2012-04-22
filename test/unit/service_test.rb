require 'test_helper'

class ServiceTest < ActiveSupport::TestCase
  test "name presence check" do
    service = Service.new(:name => "", :description => "test service")
    assert !service.save
    assert service.errors.messages[:name] == ["can't be blank"]
  end

  test "name uniqueness check" do
    service = Service.new(:name => "test", :description => "test service")
    assert service.save

    service = Service.new(:name => "test", :description => "test service 2")
    assert !service.save
    assert service.errors.messages[:name] == ["has already been taken"]
  end
end

# == Schema Information
#
# Table name: services
#
#  id          :integer(4)      not null, primary key
#  name        :string(255)
#  description :text
#  company_id  :integer(4)
#  created_at  :datetime
#  updated_at  :datetime
#

