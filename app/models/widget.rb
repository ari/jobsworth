class Widget < ActiveRecord::Base
  belongs_to :company
  belongs_to :user

  validates_presence_of :name
end
