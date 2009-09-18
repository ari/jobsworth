puts "Seeding DB"

ranges = []
distant_past = "Time.utc(1000)"
ranges << [ "Today", { :start => "Date.today", :end => "Date.tomorrow" } ]
ranges << [ "Tomorrow", { :start => "Date.tomorrow", :end => "Date.tomorrow + 1.day" } ]
ranges << [ "Yesterday", { :start => "Date.yesterday", :end => "Date.today" } ]
ranges << [ "This week", { :start => "Date.today.at_beginning_of_week", :end => "Date.today.at_end_of_week" } ]
ranges << [ "In the past", { :start => distant_past, :end => "Date.today" } ]
ranges << [ "Last week", { :start => "Date.today.at_beginning_of_week - 7", :end => "Date.today.at_beginning_of_week" } ]
ranges << [ "This month", { :start => "Date.today.at_beginning_of_month", :end => "Date.today.at_end_of_month" } ]
ranges << [ "Last month", { :start => "(Date.today.at_beginning_of_month - 10.days).at_beginning_of_month", :end => "Date.today.at_beginning_of_month" } ]
ranges << [ "This year", { :start => "Date.today.at_beginning_of_year", :end => "Date.today.at_end_of_year" } ]
ranges << [ "Last year", { :start => "(Date.today.at_beginning_of_year - 10.days).at_beginning_of_year", :end => "(Date.today.at_beginning_of_year - 10.days).at_end_of_year" } ]

ranges.each do |name, attrs|
  TimeRange.find_or_create_by_name(name).update_attributes(attrs)
end

