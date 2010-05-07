class ScmFile < ActiveRecord::Base
  belongs_to :scm_changeset, :counter_cache => true
end

# == Schema Information
#
# Table name: scm_files
#
#  id          :integer(4)      not null, primary key
#  path        :text
#  state       :string(255)

