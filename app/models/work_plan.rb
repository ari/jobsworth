class WorkPlan < ActiveRecord::Base
  WEEK_DAYS = [:monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]

  WEEK_DAYS.each do |day|
    validates day, :presence => true, :numericality => { :greater_than_or_equal_to => 0.0, :less_than_or_equal_to => 24.0, :message => I18n.t("errors.messages.between", num1: 0, num2: 24) }
  end
end
