class WorkPlan < ActiveRecord::Base
  WEEK_DAYS = [:monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]

  WEEK_DAYS.each do |day|
    validates day, :presence => true, :numericality => { :greater_than_or_equal_to => 0.0, :less_than_or_equal_to => 24.0, :message => "must be a number between 0 and 24" }
  end
end
