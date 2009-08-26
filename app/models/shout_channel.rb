# A chat channel, has many subscribed users and shouts (messages in a channel)

class ShoutChannel < ActiveRecord::Base
  belongs_to :company
  belongs_to :project

  has_many   :shouts, :dependent => :destroy, :order => "created_at"

  has_many   :shout_channel_subscriptions, :dependent => :destroy
  has_many   :subscribers, :through => :shout_channel_subscriptions, :source => :user

  validates_presence_of :name

  def last_active
    s = Shout.find(:first, :conditions => ["shout_channel_id = ?", self.id], :order => "id desc")
    s ? s.created_at : nil
  end

end
