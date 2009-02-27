var lastElement = null;
var lastPrefix = null;
var lastColor = null;
var comments = new Hash();
var last_shout = null;
var show_tooltips = 1;
var fetchTimeout = null;
var fetchElement = null;

function Hover(prefix, element) {
}

function ClearHover() {
}

function updateLoading(event){

  if($('loading').visible) {

    var scrollposY=0;
    if (window.pageYOffset){
      scrollposY = window.pageYOffset;
    }
    else if (document.documentElement && document.documentElement.scrollTop){
      scrollposY = document.documentElement.scrollTop;
        }
    else if (document.getElementById("body").scrollTop){
      scrollposY = document.getElementById("body").scrollTop;
    }

    $("loading").style.top = (scrollposY + event.clientY - 8) + "px";
    $("loading").style.left = event.clientX + 10 +"px";
    $("loading").style.zIndex=9;
  }
}

Event.observe(window, "load", function(e) {
    Event.observe(document, "mousemove", function(e) {updateLoading(e);} );
});

function tip(myEvent,tip){
  var scrollposY=0;
  if (window.pageYOffset){
    scrollposY = window.pageYOffset;
  }
  else if (document.documentElement && document.documentElement.scrollTop){
    scrollposY = document.documentElement.scrollTop;
  }
  else if (document.getElementById("body").scrollTop){
    scrollposY = document.getElementById("body").scrollTop;
  }


  var el = Event.element(myEvent);
  var taskId = null;
  if( el.toString().include("tasks/edit/") ) {
    var elements = el.toString().split("/");
    taskId = elements[elements.size()-1];
  }

  if(taskId != null) {
    var comment = comments.get(taskId);
    if( comment != null && comment != "" ) {
      var elements = comment.split("<br/>");
      var author = elements.shift();

      tip = tip.replace("</table>", "<tr><th>"+ author + "</th><td class=\"tip_description\">" + elements.join("<br/>") + "</td></tr></table>");
    }
  }

  document.getElementById("message").innerHTML= tip;

  var height = $("message").offsetHeight;
  var width = $("message").offsetWidth;
  var winwidth = (typeof(window.innerWidth) != 'undefined') ? window.innerWidth + self.pageXOffset - 20 : document.documentElement.clientWidth + document.documentElement.scrollLeft;
  var winBottom = (typeof(window.innerHeight) != 'undefined') ? window.innerHeight + self.pageYOffset - 20 : document.documentElement.clientHeight + document.documentElement.scrollTop;

  var top = scrollposY + myEvent.clientY + 15;

  if((top + height) > winBottom ) {
    top = top - height - 25;
  }

  document.getElementById("tip").style.top = top + "px";

  var left = myEvent.clientX - 25;
  if( left < 0 ) {
    left = 0;
  }

  if( (left + width) > winwidth ) {
    left = winwidth - width - 5;
  }

  document.getElementById("tip").style.left = left +"px";
  document.getElementById("tip").style.zIndex=99;
  document.getElementById("tip").style.visibility="visible";

  if( el.toString().include("tasks/edit/") && comments.get( taskId ) == null && fetchTimeout == null ) {
    fetchElement = el;
    fetchTimeout = setTimeout('fetchComment(fetchElement)', 1000);
  }
}

function hide(e){
  document.getElementById("tip").style.visibility="hidden";
  if(fetchTimeout != null) {
    clearTimeout(fetchTimeout);
    fetchTimeout = null;
    fetchElement = null;
  }
}

function fetchComment(e) {
  var elements = e.toString().split("/");
  var taskId = elements[elements.size()-1];
  new Ajax.Request('/tasks/get_comment/' + taskId, {asynchronous:true, evalScripts:true, onComplete:function(request){updateComment(taskId);} } );
}

function updateComment(taskId) {
  if(taskId != null) {
    var comment = comments.get(taskId);
    if( comment != null && comment != "" ) {
      var elements = comment.split("<br/>");
      var author = elements.shift();
      Element.insert("task_tooltip", { bottom: "<tr><th>"+ author + "</th><td class=\"tip_description\">" + elements.join("<br/>") + "</td></tr>"  } );
    }
  }
}

function makeTooltips(show) {
  $$('.tooltip').each( function(el) {
      if( show == 1 ) {
        var tooltip = el.title.replace(/&quot;/, "\"").replace(/&gt;/,"<").replace(/&lt;/,">");
        Event.observe(el, "mousemove", function(e) { tip(e, tooltip ); });
        Event.observe(el, "mouseout", function(e) { hide(e); });
      }
      el.title = '';
      Element.removeClassName(el, 'tooltip');
    } );

  Event.observe(document, "mousedown", function(e) {hide(e);} );
  show_tooltips = show;
}

function updateTooltips() {
  makeTooltips(show_tooltips);
}

function init_shout() {
  if($('shout_body')) {
    Event.observe($('shout_body'), "keypress", function(e) {
        switch( e.keyCode ) {
        case Event.KEY_RETURN:
          if (e.shiftKey) {
            return;
          } else {
            if($('shout_body').value.length > 0) {
              if(e.ctrlKey || e.metaKey) {
                $('shout-input').onsubmit();
                $('shout_body').value = '';
              } else {
                $('shout-input').onsubmit();
                $('shout_body').value = '';
              }
            }
            Event.stop(e);
          }
        }
      });
  }
}

function inline_image(el) {
  $(el).setStyle({width:'auto', visibility:'hidden'});
  if (el.width > 500) {
    el.style.width = '500px';
  }
  el.style.visibility = 'visible';
}

function HideAjax() {
  var a = document.getElementsByClassName( 'ajax', 'div' );
  for( var i = 0; i < a.length; i++ )
    Element.hide(a[i]);
}

function HideMenus() {
  var a = document.getElementsByClassName( 'amenu', 'div' );
  for( var i = 0; i < a.length; i++ )
    Element.hide(a[i]);
}

function ShowMenus() {
  var a = document.getElementsByClassName( 'amenu', 'div' );
  for( var i = 0; i < a.length; i++ )
    Element.show(a[i]);
}

function HideDummy() {
//  var a = document.getElementsByClassName( 'dummy', 'li' );
//  for( var i = 0; i < a.length; i++ ) {
//    Element.removeClassName( a[i], "task");
//    Element.hide(a[i]);
//  }

//  var a = document.getElementsByClassName( 'dummy', 'ul' );
//  for( var i = 0; i < a.length; i++ ) {
//    Element.removeClassName( a[i], "comp_drag");
//    Element.hide(a[i]);
//  }

}

function ShowDummy() {
//  var a = document.getElementsByClassName( 'dummy', 'li' );
//  for( var i = 0; i < a.length; i++ ) {
//    Element.addClassName( a[i], "task");
//    Element.show(a[i]);
//  }
//  var a = document.getElementsByClassName( 'dummy', 'ul' );
//  for( var i = 0; i < a.length; i++ ) {
//    Element.addClassName( a[i], "component_drag");
//    Element.show(a[i]);
//  }
//  UpdateDnD();
}

function UpdateDnD() {
  //Sortable.destroy('tasks_sortable');
  //Sortable.destroy('components_sortable');
  //Sortable.create("components_sortable", {dropOnEmpty:true, handle:'handle_comp', onUpdate:function(){new Ajax.Request('/components/ajax_order_comp', {asynchronous:true, evalScripts:true, onComplete:function(request){Element.hide('loading');}, onLoading:function(request){Element.show('loading');}, parameters:Sortable.serialize("components_sortable")})}, only:'component', tree:true});
  //Sortable.create('tasks_sortable', {dropOnEmpty:true, handle:'handle', onUpdate:function(){new Ajax.Request('/components/ajax_order', {asynchronous:true, evalScripts:true, onComplete:function(request){Element.hide('loading');}, onLoading:function(request){Element.show('loading');}, parameters:Sortable.serialize("tasks_sortable")})}, only:'task', tree:true});
  updateTooltips();
}

function EnableDND() {
  Element.hide('enable_dnd');
  HideMenus();
  Sortable.create("components_sortable", {dropOnEmpty:true, handle:'handle_comp', onUpdate:function(){new Ajax.Request('/components/ajax_order_comp', {asynchronous:true, evalScripts:true, onComplete:function(request){Element.hide('loading');}, onLoading:function(request){Element.show('loading');}, parameters:Sortable.serialize("components_sortable")});}, only:'component', tree:true});
  Sortable.create("tasks_sortable", {dropOnEmpty:true, handle:'handle', onUpdate:function(){new Ajax.Request('/components/ajax_order', {asynchronous:true, evalScripts:true, onComplete:function(request){Element.hide('loading');}, onLoading:function(request){Element.show('loading');}, parameters:Sortable.serialize("tasks_sortable")});}, only:'task', tree:true});
  var h = document.getElementsByClassName( 'handle', 'img' );;
  for( var i = 0; i < h.length; i++ ) {
    Element.show( h[i] );
  }
  var h = document.getElementsByClassName( 'handle_comp', 'img' );;
  for( var i = 0; i < h.length; i++ ) {
    Element.show( h[i] );
  }
  Element.show('disable_dnd');
}

function DisableDND() {
  Element.hide('disable_dnd');
  ShowMenus();
  var h = document.getElementsByClassName( 'handle', 'img' );;
  for( var i = 0; i < h.length; i++ ) {
    Element.hide( h[i] );
  }
  var h = document.getElementsByClassName( 'handle_comp', 'img' );;
  for( var i = 0; i < h.length; i++ ) {
    Element.hide( h[i] );
  }
  Element.show('enable_dnd');
}

function do_update(user, url) {
  if( user != userId ) {
    new Ajax.Request(url, {asynchronous: true, evalScripts: true });
  }
}

function do_execute(user, code) {
  if( user != userId ) {
//    alert(code);
    eval(code);
  }
}

function enableControl(id, enabled) {
  if (typeof(enabled) == "undefined") enabled = true;
  var control = $(id);
  if (!control) return;
  control.disabled = !enabled;
}

function json_decode(txt) {
  try {
    return eval( '(' + txt + ')' );
  } catch(ex) {}
}

function updateSelect(sel, response) {

   response.evalScripts();

   var lines = response.split('\n');

   var obj = json_decode(lines[0]);
   sel.options.length = 0;
   var opts = obj.options;
   for( var i=0; i<opts.length; i++ ) {
     sel.options[i] = new Option(opts[i].text,opts[i].value,null,false);
   }
}

function fixShortLinks() {
  $$('.task-name a').each( function(e) {
      e.target = '_blank';
    });

  $$('a.stop-work-link').each(function(e) {
      if( e.href != '#' ) {
        Event.observe(e, "click", function(e) {
            new Ajax.Request('/tasks/stop_work_shortlist', {asynchronous:true, evalScripts:true, onComplete:function(request){Element.hide('loading');}, onLoading:function(request){Element.show('loading');}});
            return false;
          });
        e.href = '#';
      }

    });

}

function toggleChatPopupEvent(e) {
  var el = Event.element(e);
  toggleChatPopup(el);
}

function toggleChatPopup(el) {
  if( Element.hasClassName(el.up(), 'presence-section-active') ) {
    Element.removeClassName(el.up(), 'presence-section-active');
    $$("#" + el.up().id + " .presence-shadow").each(function(e) { Element.hide(e); });
    new Ajax.Request('/shout/chat_hide/' + el.up().id, {asynchronous:true, evalScripts:true});
  } else if(Element.hasClassName(el.up(), 'presence-section')) {
    $$('.presence-section-active').each(function(el) {
					  Element.removeClassName(el, 'presence-section-active');
					  $$(".presence-shadow").each(function(el) { Element.hide(el); });
					});
    Element.addClassName(el.up(), 'presence-section-active');

    if( Element.hasClassName(el.up(), 'presence-section-pending') ) {
      Element.removeClassName(el.up(), 'presence-section-pending');
    }
    $$("#" + el.up().id + " .presence-shadow").each(function(e) { Element.show(e); });
    $$("#" + el.up().id + " input").each(function(e) { e.focus(); });

    new Ajax.Request('/shout/chat_show/' + el.up().id, {asynchronous:true, evalScripts:true});
  }
}

function closeChat(el) {
  new Ajax.Request('/shout/chat_close/' + el.up().id, {asynchronous:true, evalScripts:true});
  Element.remove(el);
}

function addMilestone() {
  var val = $('task_project_id').value;
  var popup = window.open("/milestones/quick_new?project_id=" + val, 'NewMilestone', 'height=320,width=550,toolbar=0,location=0,status=0,menubar=0');
  popup.focus();
}

function refreshMilestones(pid,mid) {
  new Ajax.Updater('task_milestone_id', '/tasks/get_milestones', {asynchronous:true, evalScripts:true, onComplete:function(request){Element.hide('loading');$('task_milestone_id').value=mid;}, onLoading:function(request){Element.show('loading');}, parameters:'project_id=' + pid, insertion: updateSelect });
}
