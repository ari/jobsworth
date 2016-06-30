class MoveSnippetsToSnippetsTable < ActiveRecord::Migration
  def up
    Page.snippets.each do |p|
      snippet = Snippet.new
      snippet.name = p.name
      snippet.body = CGI::unescapeHTML(p.body.gsub(/<\/?[^>]*>/, ''))
      snippet.user_id = p.user_id
      snippet.company_id = p.company_id
      snippet.save
    end
  rescue
    puts "WARNING: migrate snippets failed. If you don't use snippets, ignore this warning."
  end

  def down
  end
end
