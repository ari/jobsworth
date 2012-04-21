require "test_helper"

class GeneratedReportTest < ActiveRecord::TestCase
  fixtures :generated_reports

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end







# == Schema Information
#
# Table name: generated_reports
#
#  id         :integer(4)      not null, primary key
#  company_id :integer(4)
#  user_id    :integer(4)
#  filename   :string(255)
#  report     :text
#  created_at :datetime
#
# Indexes
#
#  fk_generated_reports_company_id  (company_id)
#  fk_generated_reports_user_id     (user_id)
#

