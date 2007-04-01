class Shout < ActiveRecord::Base
  belongs_to :company 
  belongs_to :user
end
