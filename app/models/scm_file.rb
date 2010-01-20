class ScmFile < ActiveRecord::Base
  has_many :scm_revisions, :dependent => :destroy
  belongs_to :project
  belongs_to :company
end

# == Schema Information
#
# Table name: scm_files
#
#  id          :integer(4)      not null, primary key
#  project_id  :integer(4)
#  company_id  :integer(4)
#  name        :text
#  path        :text
#  state       :string(255)
#  commit_date :datetime
#

