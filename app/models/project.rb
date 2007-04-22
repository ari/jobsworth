class Project < ActiveRecord::Base
  belongs_to    :company
  belongs_to    :customer
  belongs_to    :owner, :class_name => "User", :foreign_key => "user_id"

  has_many      :users, :through => :project_permissions
  has_many      :project_permissions, :dependent => :destroy
  has_many      :pages, :dependent => :destroy
  has_many      :tasks
  has_many      :sheets
  has_many      :work_logs
  has_many      :activities
  has_many      :project_files, :dependent => :destroy
  has_many      :milestones, :dependent => :destroy

  validates_length_of           :name,  :maximum=>200
  validates_presence_of         :name

  def full_name
    "#{name}"
  end

  def to_css_name
    "#{self.name.underscore.dasherize.gsub(/[ \."',]/,'-')} #{self.customer.name.underscore.dasherize.gsub(/[ \.'",]/,'-')}"
  end

end
