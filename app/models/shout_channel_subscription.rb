class ShoutChannelSubscription < ActiveRecord::Base
  belongs_to :shout_channel
  belongs_to :user
end
