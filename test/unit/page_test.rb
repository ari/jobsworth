require "test_helper"

class PageTest < ActiveRecord::TestCase

  should belong_to(:company)
  should belong_to(:user)
  should belong_to(:notable)

  should validate_presence_of(:name)

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
#  snippet      :boolean(1)      default(FALSE)
#
# Indexes
#
#  pages_company_id_index                      (company_id)
#  index_pages_on_notable_id_and_notable_type  (notable_id,notable_type)
#  fk_pages_user_id                            (user_id)
#

