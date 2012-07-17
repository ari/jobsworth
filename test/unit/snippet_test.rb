require 'test_helper'

class SnippetTest < ActiveSupport::TestCase
  should "be able to create new snippet" do
    assert Snippet.create(:name => "test", :body => "some content")
  end

  should "be unable to create snippet without body" do
    assert !Snippet.new(:name => "test snippet").save
  end

  should "be unable to create snippet without name" do
    assert !Snippet.new(:body => "some text").save
  end
end
