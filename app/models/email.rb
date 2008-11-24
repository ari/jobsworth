# Simple storage of received emails, pretty much
# only used for debugging why an incoming email
# failed

class Email < ActiveRecord::Base
  belongs_to :company
  belongs_to :user
end
