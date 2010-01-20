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

# == Schema Information
#
# Table name: pages
#
#  id           :integer(4)      not null, primary key
#  name         :string(200)     default(""), not null
#  body         :text
#  company_id   :integer(4)      default(0), not null
#  user_id      :integer(4)      default(0), not null
#  created_at   :datetime
#  updated_at   :datetime
#  position     :integer(4)
#  notable_id   :integer(4)
#  notable_type :string(255)
#

