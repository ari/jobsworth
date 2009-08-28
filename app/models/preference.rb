# A simple key/value preference. 
class Preference < ActiveRecord::Base

  # N.B Currently this is only implemented
  # on Company, but it is polymorphic because i) it seems pretty likely
  # projects, etc will need this, and ii) there is no real harm by making
  # it polymorphic.

  belongs_to :preferencable, :polymorphic => true
end
