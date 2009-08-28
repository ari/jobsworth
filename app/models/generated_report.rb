# Cached result of a report, used for downloading a prevously run
# report via CSV as the underlying data can have changed between 
# the running of the report and the downloading

class GeneratedReport < ActiveRecord::Base
  belongs_to :company
  belongs_to :user

end
