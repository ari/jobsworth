# A simple key/value preference. 
class Preference < ActiveRecord::Base

  # N.B Currently this is only implemented
  # on Company, but it is polymorphic because i) it seems pretty likely
  # projects, etc will need this, and ii) there is no real harm by making
  # it polymorphic.

  belongs_to :preferencable, :polymorphic => true
end

# == Schema Information
#
# Table name: preferences
#
#  id                 :integer(4)      not null, primary key
#  preferencable_id   :integer(4)
#  preferencable_type :string(255)
#  key                :string(255)
#  value              :text
#  created_at         :datetime
#  updated_at         :datetime
#

