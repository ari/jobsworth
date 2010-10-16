function update_gantt(gantt_type, gannt_id, duration, end_date) {
  if (gantt_type=='task'){ var action = 'gantt_save'} else {var action = 'gantt_milestone_save'};
  jQuery.post("/schedule/" + action + "/"+ gannt_id + "?duration=" +  duration + "&due_date=" + end_date);
}

var DateUtils = {
  daysBetween: function (start, end) {
    if (!start || !end) { return 0; }
      start = Date.parse(start); end = Date.parse(end);
      if (start.getYear() == 1901 || end.getYear() == 8099) { return 0; }
      var count = 0, date = start.clone();
      while (date.compareTo(end) == -1) { count = count + 1; date.addDays(1); }
      return count;
  },

  isWeekend: function (date) {
    return date.getDay() % 6 == 0;
  }
};

function show_gantt(gantt_data, start_date, end_date) {
  jQuery("#ganttChart").ganttView({
    data: gantt_data,
    start: start_date,
    end: end_date,
    slideWidth: 550,
    behavior: {
      onResize: function (data) {
        update_gantt(data.gantt_type, data.gantt_id, DateUtils.daysBetween(data.start, data.end) + 1, data.end.toString("dd/MM/yyyy"));
      },
      onDrag: function (data) {
         update_gantt(data.gantt_type, data.gantt_id, DateUtils.daysBetween(data.start, data.end) + 1, data.end.toString("dd/MM/yyyy"));
      }
    }
  });
}

function refresh_gantt() {
  jQuery.ajax({
    url: '/schedule/gantt_data?format=js',
    dataType: 'script',
    success:function(response) {
      gantt_data = eval(response);
      jQuery("#ganttChart").empty();
      show_gantt(gantt_data, Date.today(), Date.parse("+2months"));
    },
    beforeSend: function(){ showProgress(); },
    complete: function(){ hideProgress(); },
    error:function (xhr, thrownError) {
      alert("Invalid task list model returned from server");
    }
  });
};