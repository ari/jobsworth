require 'spec_helper'

describe NewsItem do
  describe "Validations" do
    it "should not be valid if the body field is blank" do
      news_item = NewsItem.new(:body => '', :portal => true)
      news_item.should_not be_valid
    end

    it "should not be valid if the portal field is blank" do
      news_item = NewsItem.new(:body => 'Lol', :portal => '')
      news_item.should_not be_valid
    end
  end

  describe "Default Scope" do
    before :each do
      @news_item_1 = NewsItem.make(:created_at  => Time.now)
      @news_item_2 = NewsItem.make(:created_at  => Time.now + 20.minutes)
    end

    it "should return a list of all the news items ordered by creation date" do
      all_news = NewsItem.all
      all_news.first.should == @news_item_2
    end
  end
end

# == Schema Information
#
# Table name: news_items
#
#  id         :integer(4)      not null, primary key
#  created_at :datetime
#  body       :text
#  portal     :boolean(1)      default(TRUE)
#

