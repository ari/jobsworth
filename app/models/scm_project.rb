# encoding: UTF-8
#location - ulr of the repository
require 'digest/md5'
class ScmProject < ActiveRecord::Base
  belongs_to :company
  has_many :scm_changesets
  validates_presence_of :company
  before_create do |scm_project|
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
#  secret_key       :string(255)
#
# Indexes
#
#  fk_scm_projects_company_id  (company_id)
#

