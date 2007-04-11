class WikiPage < ActiveRecord::Base
  has_many :revisions, :class_name => 'WikiRevision', :order => 'id'
  has_one  :current_revision, :class_name => 'WikiRevision', :order => 'id DESC'
  belongs_to :company

  LOCKING_PERIOD = 30.minutes
  CamelCase = Regexp.new( '\b((?:[A-Z]\w+){2,})' )
  WIKI_LINK = /\[\[\s*([^\]\s][^\]]+?)\s*\]\]/
#  WIKI_LINK = Regexp.new('\[\[([^\]]+?)\]\]')
#  LINK_TYPE_SEPARATION = Regexp.new('^(.+):((file)|(pic))$', 0, 'utf-8')
  ALIAS_SEPARATION = Regexp.new('^(.+)\|(.+)$', 0, 'utf-8')

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

  def continous_revision?(time, author)
    (current_revision.author == author) && (revised_at + 30.minutes > time)
  end

  def locked_by
    User.find( self.attributes['locked_by'] ) unless self.attributes['locked_by'].nil?
  end

  def to_html
    body = current_revision.body


    body.gsub!( WIKI_LINK ) { |m|
      match = m.match(WIKI_LINK)
      name = text = match[1]

      alias_match = match[1].match(ALIAS_SEPARATION)
      if alias_match
        name = alias_match[1]
        text = alias_match[2]
      end

      "\"#{text}\":/wiki/show/#{URI.encode(name)}"
    }
#    body.gsub!( CamelCase, '"\1":/wiki/show/\1')

    RedCloth.new(body).to_html
  end

end
