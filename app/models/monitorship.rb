class Monitorship < ActiveRecord::Base
  belongs_to :user
  belongs_to :monitorship, :polymorphic => true

  belongs_to :topic, :foreign_key => :monitorship_id
  belongs_to :forum, :foreign_key => :monitorship_id
end


# == Schema Information
#
# Table name: monitorships
#
#  id               :integer(4)      not null, primary key
#  monitorship_id   :integer(4)
#  user_id          :integer(4)
#  active           :boolean(1)      default(TRUE)
#  monitorship_type :string(255)
#
# Indexes
#
#  index_monitorships_on_user_id  (user_id)
#

