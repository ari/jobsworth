# Users with moderation rights to forums. Not really used yet.

class Moderatorship < ActiveRecord::Base
  belongs_to :forum
  belongs_to :user
  before_create { |r| where('forum_id = ? and user_id = ?', r.forum_id, r.user_id).count.zero? }
end


# == Schema Information
#
# Table name: moderatorships
#
#  id       :integer(4)      not null, primary key
#  forum_id :integer(4)
#  user_id  :integer(4)
#
# Indexes
#
#  index_moderatorships_on_forum_id  (forum_id)
#  fk_moderatorships_user_id         (user_id)
#

