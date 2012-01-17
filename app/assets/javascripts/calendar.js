function refresh_calendar(resources) {
  jQuery("#calendar").empty();
  jQuery("#calendar").fullCalendar({
    events: "/tasks/calendar",
    resources: resources,
    header: {
      left: '',
      center: 'title',
      right: 'prev,next today resourceMonth,month'
    },
    defaultView: 'resourceMonth',
    selectable: true,
    selectHelper: true,
    select: function(start, end, allDay, jsEvent, view, resource) {},
    eventDrop: function( event, dayDelta, minuteDelta, allDay, revertFunc, jsEvent, ui, view ) {},
    eventResize: function( event, dayDelta, minuteDelta, revertFunc, jsEvent, ui, view ) {},
    eventClick: function ( event, jsEvent, view ) { loadTask(event.id); },
    eventRender: function( event, element, view ) {}
  });

};
