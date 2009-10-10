require File.dirname(__FILE__) + '/../test_helper'

class PageTest < ActiveRecord::TestCase

  should_belong_to :company
  should_belong_to :user
  should_belong_to :notable

  should_validate_presence_of :name

  context "A normal page" do
    setup do
      @page = Page.make
    end
    subject { @page }
    

    should "require a notable" do
      @page.notable = nil
      assert !@page.valid?

      @page.notable = User.make
      assert @page.valid?
    end
  end

end
