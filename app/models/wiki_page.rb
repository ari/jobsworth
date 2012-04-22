# encoding: UTF-8
# A wiki page

class WikiPage < ActiveRecord::Base
  has_many :revisions, :class_name => 'WikiRevision', :order => 'id'
  has_many :references, :class_name => 'WikiReference', :order => 'referenced_name'
  has_one  :current_revision, :class_name => 'WikiRevision', :order => 'id DESC'
  belongs_to :company

  has_many   :event_logs, :as => :target, :dependent => :destroy, :order => 'id DESC'

  LOCKING_PERIOD = 30.minutes

  def lock(time, locked_by)
    update_attributes(:locked_at => time, :locked_by => locked_by)
  end

  def lock_duration(time)
    ((time - locked_at) / 60).to_i unless locked_at.nil?
  end

  def unlock
    update_attributes(:locked_at => nil, :locked_by => nil)
  end

  def locked?
    locked_at + LOCKING_PERIOD > Time.now.utc unless locked_at.nil?
  end

  def locked_by
    User.find( self.attributes['locked_by'] ) unless self.attributes['locked_by'].nil?
  end

  # SELECT wiki_pages.* FROM wiki_pages LEFT OUTER JOIN wiki_references w_r ON wiki_pages.id = w_r.wiki_page_id WHERE  w_r.referenced_name = 'pagename';
  def pages_linking_here
    @refs ||= WikiPage.select("wiki_pages.*").joins("LEFT OUTER JOIN wiki_references w_r ON wiki_pages.id = w_r.wiki_page_id").where("w_r.referenced_name = ? AND wiki_pages.company_id = ?", self.name, self.company_id)
  end

  def to_url
    "<a href=\"/wiki/show/#{URI.encode(name)}\">#{name}</a>".html_safe
  end

  def body
    current_revision.body
  end

  def user
    current_revision.user
  end

  def revision(rev = 0)
    rev > 0 ? self.revisions[rev-1] : current_revision
  end 
    

  def to_html(rev = 0)
    if rev > 0
      self.revisions[rev-1].to_html
    else
      current_revision.to_html
    end
  end

  def to_plain_html(rev = 0)
    if rev > 0
      self.revisions[rev-1].to_plain_html
    else
      current_revision.to_plain_html
    end
  end

  def started_at
    self.created_at
  end
  
end






# == Schema Information
#
# Table name: wiki_pages
#
#  id         :integer(4)      not null, primary key
#  company_id :integer(4)
#  project_id :integer(4)
#  created_at :datetime
#  updated_at :datetime
#  name       :string(255)
#  locked_at  :datetime
#  locked_by  :integer(4)
#
# Indexes
#
#  wiki_pages_company_id_index  (company_id)
#

