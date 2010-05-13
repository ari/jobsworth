#location - ulr of the repository
require 'digest/md5'
class ScmProject < ActiveRecord::Base
  belongs_to :project
  belongs_to :company
  has_many :scm_changesets
  validates_presence_of :project
  before_create do |scm_project|
    scm_project.company = scm_project.project.company if scm_project.company.nil? and !scm_project.project.nil?
    scm_project.secret_key = Digest::MD5.hexdigest( rand(100000000).to_s + Time.now.to_s)[0..11]
  end
end


# == Schema Information
#
# Table name: scm_projects
#
#  id               :integer(4)      not null, primary key
#  project_id       :integer(4)
#  company_id       :integer(4)
#  scm_type         :string(255)
#  last_commit_date :datetime
#  last_update      :datetime
#  last_checkout    :datetime
#  module           :text
#  location         :text
#
# Indexes
#
#  fk_scm_projects_company_id  (company_id)
#

