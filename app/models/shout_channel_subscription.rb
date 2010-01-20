# A user subscribing to a shout_channel (chat channel)

class ShoutChannelSubscription < ActiveRecord::Base
  belongs_to :shout_channel
  belongs_to :user
end

# == Schema Information
#
# Table name: shout_channel_subscriptions
#
#  id               :integer(4)      not null, primary key
#  shout_channel_id :integer(4)
#  user_id          :integer(4)
#

