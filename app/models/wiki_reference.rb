# A reference from one WikiPage to another, to enable
# back-links

class WikiReference < ActiveRecord::Base
  belongs_to :wiki_page

end
