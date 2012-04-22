# encoding: UTF-8
# Cached result of a report, used for downloading a prevously run
# report via CSV as the underlying data can have changed between 
# the running of the report and the downloading

class GeneratedReport < ActiveRecord::Base
  belongs_to :company
  belongs_to :user

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

