# Simple storage of received emails, pretty much
# only used for debugging why an incoming email
# failed

class Email < ActiveRecord::Base
  belongs_to :company
  belongs_to :user
end

# == Schema Information
#
# Table name: emails
#
#  id         :integer(4)      not null, primary key
#  from       :string(255)
#  to         :string(255)
#  subject    :string(255)
#  body       :text
#  company_id :integer(4)
#  user_id    :integer(4)
#  created_at :datetime
#  updated_at :datetime
#

