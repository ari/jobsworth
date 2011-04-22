require 'test_helper'
class ApplicationControllerTest < ActionController::TestCase

  def ImageMagickInstalled?
   `convert`? true : false
  end

  should "have ImageMagick installed for paperclip gem works properly" do
    assert_equal true, ImageMagickInstalled?
  end

end