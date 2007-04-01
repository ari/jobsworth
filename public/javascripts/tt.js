var lastElement = null;
var lastPrefix = null;
var lastColor = null;
var tooltips = new Array;
var tooltipids = new Array;
var last_shout = null;
var show_tooltips = 1;

function Hover(prefix, element) {
  ClearHover();
  Element.show('edit' + '_' + prefix + '_' + element);
  lastColor = $(prefix + '_' + element).style.backgroundColor;
  $(prefix + '_' + element).style.backgroundColor = "#fff2d4";
  lastElement = element;
  lastPrefix = prefix;
}

function ClearHover() {
  if( lastElement != null ) {
    Element.hide('edit' + '_' + lastPrefix + '_' + lastElement);
    $(lastPrefix + '_' + lastElement).style.backgroundColor = lastColor;
  }
  lastElement = null;
  lastPrefix = null;
}

function updateLoading(event){

  scrollposY=0;
  if (window.pageYOffset){
    scrollposY = window.pageYOffset;
  }
  else if (document.documentElement && document.documentElement.scrollTop){
    scrollposY = document.documentElement.scrollTop
  }
  else if (document.getElementById("body").scrollTop){
    scrollposY = document.getElementById("body").scrollTop;
  }

  $("loading").style.top = (scrollposY + event.clientY - 8) + "px";
  $("loading").style.left = event.clientX + 10 +"px";
  $("loading").style.zIndex=9;
}

Event.observe(document, "mousemove", function(e) {updateLoading(e);} );


function tip(myEvent){

  var n = null;

  for( var i = 0; i < tooltipids.length; i++ ) {
    if( tooltipids[i] == Event.element(myEvent) ) {
      n = i;
      break;
    }
  }

  if( n == null )
    return;

  self.status=tooltips[n];
  scrollposY=0;
  if (window.pageYOffset){
    scrollposY = window.pageYOffset;
  }
  else if (document.documentElement && document.documentElement.scrollTop){
    scrollposY = document.documentElement.scrollTop
  }
  else if (document.getElementById("body").scrollTop){
    scrollposY = document.getElementById("body").scrollTop;
  }

  document.getElementById("message").innerHTML= tooltips[n];
  document.getElementById("tip").style.top = scrollposY + myEvent.clientY + 15+"px";
  var left = myEvent.clientX - 25;
  if( left < 0 ) left = 0;
  document.getElementById("tip").style.left = left +"px";
  document.getElementById("tip").style.zIndex=9;
  document.getElementById("tip").style.visibility="visible";
}



function hide(e){
        document.getElementById("tip").style.visibility="hidden";
        self.status="ClockingIT v0.99";
}


function makeTooltips(show) {
  var a = document.getElementsByClassName( 'tooltip' );
  for( var i = 0; i < a.length; i++ ) {
    if( show == 1 ) {
      tooltips[tooltips.length] = a[i].title;
      tooltipids[tooltipids.length] = a[i];
      Element.removeClassName(a[i], 'tooltip');
      Event.observe(a[i], "mousemove", function(e) { tip(e); });
      Event.observe(a[i], "mouseout", function(e) { hide(e); });
    }
    a[i].title = '';
  }
  Event.observe(document, "mousedown", function(e) {hide(e);} );
  show_tooltips = show;
}

function updateTooltips() {
  var a = document.getElementsByClassName( 'tooltip' );
  for( var i = 0; i < a.length; i++ ) {
    if( show_tooltips == 1 ) {
      tooltips[tooltips.length] = a[i].title;
      tooltipids[tooltipids.length] = a[i];
      Element.removeClassName(a[i], 'tooltip');
      Event.observe(a[i], "mousemove", function(e) { tip(e); });
      Event.observe(a[i], "mouseout", function(e) { hide(e); });
    }
    a[i].title = '';
  }
}

function init_shout() {
  Event.observe($('shout_body'), "keypress", function(e) {
      switch( e.keyCode ) {
      case Event.KEY_RETURN:
        var params = Form.Element.serialize($('shout_body'));
        $('shout_body').value = '';
        new Ajax.Request('/shout/add_ajax', {asynchronous:true, evalScripts:true, parameters: params, onComplete:function(request){Element.hide('loading');update_chat(request);}, onLoading:function(request){Element.show('loading');}}); return false;
      }
      return true;
  });
}

function update_chat(t) {
  if( last_shout == null ) {
    last_shout = t.responseText;
  } else {
    if( last_shout != t.responseText && t.responseText.indexOf('table') > 0 ) {
      last_shout = t.responseText;
    }
  }
}

function check_chat(t) {
  if( last_shout == null ) {
    last_shout = t.responseText;
  } else {
    if( last_shout != t.responseText && t.responseText.indexOf('table') > 0 ) {
      last_shout = t.responseText;
      new Effect.Pulsate( 'shouts', { duration: 2.0 } );
      //alert( "'" + t.responseText + "'" );
    }
  }
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
  Sortable.create("components_sortable", {dropOnEmpty:true, handle:'handle_comp', onUpdate:function(){new Ajax.Request('/components/ajax_order_comp', {asynchronous:true, evalScripts:true, onComplete:function(request){Element.hide('loading');}, onLoading:function(request){Element.show('loading');}, parameters:Sortable.serialize("components_sortable")})}, only:'component', tree:true});
  Sortable.create("tasks_sortable", {dropOnEmpty:true, handle:'handle', onUpdate:function(){new Ajax.Request('/components/ajax_order', {asynchronous:true, evalScripts:true, onComplete:function(request){Element.hide('loading');}, onLoading:function(request){Element.show('loading');}, parameters:Sortable.serialize("tasks_sortable")})}, only:'task', tree:true});
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