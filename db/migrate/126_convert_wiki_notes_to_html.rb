class ConvertWikiNotesToHtml < ActiveRecord::Migration
  def self.up
    say_with_time "Converting Wiki pages to HTML" do 
      WikiRevision.all.each do |rev|
        rev.body = RedCloth.new(rev.body).to_html(:block_textile_table, :block_textile_lists, :block_textile_prefix, :inline_textile_image, :inline_textile_link, :inline_textile_span)
        rev.save
      end 
    end 

    say_with_time "Converting Notes to HTML" do 
      Page.all.each do |page|
        page.body = RedCloth.new(page.body).to_html(:block_textile_table, :block_textile_lists, :block_textile_prefix, :inline_textile_image, :inline_textile_link, :inline_textile_span)
        page.save
      end 
    end 

  end

  def self.down
  end
end
