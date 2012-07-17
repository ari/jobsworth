class Snippet < ActiveRecord::Base
  belongs_to :company
  belongs_to :user

  validates :name, :presence => true
  validates :body, :presence => true
end
