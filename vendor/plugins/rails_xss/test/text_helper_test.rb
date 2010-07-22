require 'test_helper'

class TextHelperTest < ActionView::TestCase

  def setup
    @controller = Class.new do
      attr_accessor :request
      def url_for(*args) "http://www.example.com" end
    end.new
  end

  def test_simple_format_with_escaping_html_options
    assert_dom_equal(%(<p class="intro">It's nice to have options.</p>),
                     simple_format("It's nice to have options.", :class=>"intro"))
  end

end
