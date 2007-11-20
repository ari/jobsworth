class ShoutChannel < ActiveRecord::Base
  belongs_to :company
  belongs_to :project

  has_many   :shouts, :dependent => :destroy, :order => "created_at"

  def last_active
    s = Shout.find(:first, :conditions => ["shout_channel_id = ?", self.id], :order => "id desc")
    s ? s.created_at : nil
  end

end
