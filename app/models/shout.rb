# A chat message in a chat channel

class Shout < ActiveRecord::Base
  belongs_to :shout_channel
  belongs_to :company
  belongs_to :user

end

# == Schema Information
#
# Table name: shouts
#
#  id               :integer(4)      not null, primary key
#  company_id       :integer(4)
#  user_id          :integer(4)
#  created_at       :datetime
#  body             :text
#  shout_channel_id :integer(4)
#  message_type     :integer(4)      default(0)
#  nick             :string(255)
#

