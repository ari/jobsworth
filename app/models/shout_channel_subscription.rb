# A user subscribing to a shout_channel (chat channel)

class ShoutChannelSubscription < ActiveRecord::Base
  belongs_to :shout_channel
  belongs_to :user
end
