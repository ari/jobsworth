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
