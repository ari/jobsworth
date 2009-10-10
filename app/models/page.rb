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
