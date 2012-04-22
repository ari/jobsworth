# encoding: UTF-8
class ScmFile < ActiveRecord::Base
  belongs_to :scm_changeset, :counter_cache => true
end





# == Schema Information
#
# Table name: scm_files
#
#  id               :integer(4)      not null, primary key
#  path             :text
#  state            :string(255)
#  scm_changeset_id :integer(4)
#
# Indexes
#
#  index_scm_files_on_scm_changeset_id  (scm_changeset_id)
#

