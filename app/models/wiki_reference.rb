# encoding: UTF-8
# A reference from one WikiPage to another, to enable
# back-links

class WikiReference < ActiveRecord::Base
  belongs_to :wiki_page

end






# == Schema Information
#
# Table name: wiki_references
#
#  id              :integer(4)      not null, primary key
#  wiki_page_id    :integer(4)
#  referenced_name :string(255)
#  created_at      :datetime
#  updated_at      :datetime
#
# Indexes
#
#  index_wiki_references_on_wiki_page_id  (wiki_page_id)
#

