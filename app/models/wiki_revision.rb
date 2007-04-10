class WikiRevision < ActiveRecord::Base
  belongs_to :wiki_page
  belongs_to :user
end
