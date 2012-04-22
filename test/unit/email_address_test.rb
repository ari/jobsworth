require "test_helper"

class EmailAddressTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
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

