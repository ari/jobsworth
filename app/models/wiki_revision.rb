# encoding: UTF-8
# A single revision of a WikiPage

class WikiRevision < ActiveRecord::Base
  belongs_to :wiki_page
  belongs_to :user

  EXPR = Regexp.new( '\b(:?[A-Z][a-z0-9]+[A-Z][a-z0-9]+([A-Z][a-z0-9]+)*)|\[\[\s*([^\]\s][^\]]+?)\s*\]\]' )
  CamelCase = /\b(:?[A-Z][a-z0-9]+[A-Z][a-z0-9]+([A-Z][a-z0-9]+)*)/
  WIKI_LINK = /\[\[\s*([^\]\s][^\]]+?)\s*\]\]/
  PRE = /<pre>(.*?)<\/pre>/m

  TaskNumbers = /[^&]#([0-9]+)[^;"]/
  TaskNumber = /([^&])#([0-9]+)([^;"])/

  ALIAS_SEPARATION = Regexp.new('^(.+)\|(.+)$', 0)

  after_save :update_references

  def update_references

    self.wiki_page.references.destroy_all if self.wiki_page.references.size > 0

    body.gsub!( WIKI_LINK ) { |m|
      match = m.match(WIKI_LINK)
      name = text = match[1]
      alias_match = match[1].match(ALIAS_SEPARATION)
      if alias_match
        name = alias_match[1]
        text = alias_match[2]
      end

      unless name.downcase.include? '://'
        ref = WikiReference.where("wiki_page_id = ? AND referenced_name = ?", self.wiki_page.id, name).first
        if ref.nil? && self.wiki_page.name != name
          ref = WikiReference.create(:wiki_page => self.wiki_page, :referenced_name => name )
          ref.save
        end
      end
    }

    body.gsub!( CamelCase ) { |m|
      match = m.match(CamelCase)
      name = text = match[1]

      unless name.downcase.include? '://'
        ref = WikiReference.where("wiki_page_id = ? AND referenced_name = ?", self.wiki_page.id, name).first
        if ref.nil? && self.wiki_page.name != name
          ref = WikiReference.create(:wiki_page => self.wiki_page, :referenced_name => name )
          ref.save
        end
      end
    }

  end

  def to_html
    return "" if body.blank?
    
    pres = []

    body.gsub!( PRE ) { |m|
      match = m.match(PRE)
      pres << match[1]
      "%%pre_#{pres.size-1}%%"
    }

    body.gsub!( EXPR ) { |m|
      match = m.match(WIKI_LINK)
      if match
        name = text = match[1]

        alias_match = match[1].match(ALIAS_SEPARATION)
        if alias_match
          name = alias_match[1]
          text = alias_match[2]
        end

        name.strip!

        if name.downcase.include? '://'
          url = name
          url_class = 'external'
        else
          url = "/wiki/show/#{URI.encode(name)}"
          url_class = 'internal'
          url_class << '_missing' unless WikiPage.where('company_id = ? and name = ?', self.wiki_page.company_id, name).first
        end

        "<a href=\"#{url}\" class=\"#{url_class}\">#{text}</a>"

      else
        url = "/wiki/show/#{URI.encode(m)}"
        url_class = 'internal'
        url_class << '_missing' unless WikiPage.where('company_id = ? and name = ?', self.wiki_page.company_id, m).first

        "<a href=\"#{url}\" class=\"#{url_class}\">#{m}</a>"
      end
   }

    body.gsub!( TaskNumbers ) { |m| 
      _, before, num, after = TaskNumber.match(m).to_a
      "#{before}<a href=\"/tasks/view/#{num}\">##{num}</a>#{after}"
    }

    i = 0
    while i < pres.size
      body.gsub!(/%%pre_#{i}%%/) { |m|
        pres[i]
      }
      i = i + 1
    end 
    body

  end

  def to_plain_html
    body
  end 			

end







# == Schema Information
#
# Table name: wiki_revisions
#
#  id           :integer(4)      not null, primary key
#  wiki_page_id :integer(4)
#  created_at   :datetime
#  updated_at   :datetime
#  body         :text
#  user_id      :integer(4)
#  change       :string(255)
#
# Indexes
#
#  fk_wiki_revisions_user_id          (user_id)
#  wiki_revisions_wiki_page_id_index  (wiki_page_id)
#

