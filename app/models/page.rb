# Stand-alone Page (called Note inside the application) with information a user frequently
# needs. 

class Page < ActiveRecord::Base
  belongs_to :company
  belongs_to :user
  belongs_to :notable, :polymorphic => true

  validates_presence_of :name

  named_scope :projects, :conditions => [ "notable_type = 'Project'" ]

  protected

  def validate
    if notable.nil?
      errors.add_to_base("Target required")
    end
  end

end

# == Schema Information
#
# Table name: pages
#
#  id           :integer(4)      not null, primary key
#  name         :string(200)     default(""), not null
#  body         :text
#  company_id   :integer(4)      default(0), not null
#  user_id      :integer(4)      default(0), not null
#  created_at   :datetime
#  updated_at   :datetime
#  position     :integer(4)
#  notable_id   :integer(4)
#  notable_type :string(255)
#

