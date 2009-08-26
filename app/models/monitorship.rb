class Monitorship < ActiveRecord::Base
  belongs_to :user
  belongs_to :monitorship, :polymorphic => true

  belongs_to :topic, :foreign_key => :monitorship_id
  belongs_to :forum, :foreign_key => :monitorship_id
end
