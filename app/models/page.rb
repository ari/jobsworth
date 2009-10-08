# Stand-alone Page (called Note inside the application) with information a user frequently
# needs. 

class Page < ActiveRecord::Base
  belongs_to :company
  belongs_to :project
  belongs_to :user
  belongs_to :notable, :polymorphic => true

  acts_as_list  :scope => :project

  validates_presence_of :name

  protected

  def validate
    if project.nil? and notable.nil?
      errors.add_to_base("Target required")
    end
  end

end
