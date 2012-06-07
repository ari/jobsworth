require "test_helper"

class EmailAddressTest < ActiveSupport::TestCase
  test "invalid email format should fail" do
    assert_raise(ActiveRecord::RecordInvalid) { EmailAddress.create!(:email => "invalid email address") }
  end

  test "duplicate email should fail" do
    email = EmailAddress.make
    assert_raise(ActiveRecord::RecordInvalid) { EmailAddress.create!(:email => email.email) }
  end

  test "email must be present" do
    assert_raise(ActiveRecord::RecordInvalid) { EmailAddress.create!(:email => nil) }
  end

  test "email without user_id is OK" do
    assert_nothing_raised { EmailAddress.create!(:email => Faker::Internet.email) }
  end

  test "normal email can be created" do
    user = User.make
    assert_nothing_raised { EmailAddress.create!(:email => Faker::Internet.email, :user => user) }
  end
end




# == Schema Information
#
# Table name: email_addresses
#
#  id         :integer(4)      not null, primary key
#  user_id    :integer(4)
#  email      :string(255)
#  default    :boolean(1)
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  fk_email_addresses_user_id  (user_id)
#

