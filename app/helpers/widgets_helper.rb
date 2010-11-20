# encoding: UTF-8
module WidgetsHelper
  SCHEDULE_HEADERS = ["Overdue", "Today", "Tomorrow", "This Week", "Next Week"]

  def schedule_header(i)
    SCHEDULE_HEADERS[i]
  end
  
end
