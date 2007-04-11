class WikiRevision < ActiveRecord::Base
  belongs_to :wiki_page
  belongs_to :user

  CamelCase = Regexp.new( '\b((?:[A-Z]\w+){2,})' )
  WIKI_LINK = /\[\[\s*([^\]\s][^\]]+?)\s*\]\]/
#  LINK_TYPE_SEPARATION = Regexp.new('^(.+):((file)|(pic))$', 0, 'utf-8')

  TaskNumber = /#([0-9]+)/

  ALIAS_SEPARATION = Regexp.new('^(.+)\|(.+)$', 0, 'utf-8')

  def to_html
    body.gsub!( WIKI_LINK ) { |m|
      match = m.match(WIKI_LINK)
      name = text = match[1]

      alias_match = match[1].match(ALIAS_SEPARATION)
      if alias_match
        name = alias_match[1]
        text = alias_match[2]
      end

      if name.downcase.include? '://'
        url = name
      else
        url = "/wiki/show/#{URI.encode(name)}"
      end

      "\"#{text}\":#{url}"
    }
#    body.gsub!( CamelCase, '"\1":/wiki/show/\1')

    body.gsub!( TaskNumber, '"#\1":/tasks/view/\1')

    RedCloth.new(body).to_html + "<br/>"

  end
end
