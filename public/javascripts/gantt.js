var ganttIsDragging = 0;
var ganttLastX = 0;

function ganttDragging(e) {

  if(ganttIsDragging == 1) {
    setTimeout(function() { ganttDragging(e);}, 1000);
    var w = Element.getWidth(e);
    var x = Element.positionedOffset(e)[0];
    if( x != ganttLastX) {
      new Ajax.Request('/schedule/gantt_dragging/' + e.id + "?x=" + x + "&w=" + w);
      ganttLastX = x;
    }
  }
}

function ganttDragEnd(ev) {
  ganttIsDragging = 0;
  var e = ev.element;
  var w = Element.getWidth(e);
  var x = Element.positionedOffset(e)[0];


  new Ajax.Request('/schedule/gantt_drag/' + e.id + "?x=" + x + "&w=" + w);
}


function ganttDragStart(ev) {
  ganttIsDragging = 1;
  var e = ev.element;
  var w = Element.getWidth(e);
  var x = Element.positionedOffset(e)[0];
  setTimeout( function() { ganttDragging(e);} , 1000);
}

jQuery(document).ready(function() {
	jQuery("input[id^=due-]").datepicker({dateFormat: userDateFormat});
	jQuery("input[id^=due-tasks]").blur(function(){
		value = jQuery(this).val();
		id = jQuery(this).attr('id').match(/\d+/);
		jQuery.post('/schedule/reschedule/' + id,{due: value});
	});
	jQuery("input[id^=due-milestones]").blur(function(){
		value = jQuery(this).val();
		id = jQuery(this).attr('id').match(/\d+/);
			jQuery.post('/schedule/reschedule_milestone/' + id,{due: value});
	});
});