var InternetExplorer=navigator.appName.indexOf("Microsoft")!=-1;var connected=false;function myFlash_DoFSCommand(command,args){flashData(args);}
function juggernautInit(){if(navigator.appName&&navigator.appName.indexOf("Microsoft")!=-1&&navigator.userAgent.indexOf("Windows")!=-1&&navigator.userAgent.indexOf("Windows 3.1")==-1){document.write('<SCRIPT LANGUAGE=VBScript\> \n');document.write('on error resume next \n');document.write('Sub myFlash_FSCommand(ByVal command, ByVal args)\n');document.write(' call myFlash_DoFSCommand(command, args)\n');document.write('end sub\n');document.write('</SCRIPT\> \n');}}
function flashData(data){eval(utf8to16(decode64(data)));}
function flashConnected(){connected=true;}
function flashErrorConnecting(){Element.update('flash_message','Unable to connect to push server...');Element.show('flash');new Effect.Highlight('flash_message',{duration:2.0});}
function flashConnectionLost(){Element.update('flash_message','Connection to push server lost. Please reload the page...');Element.show('flash');new Effect.Highlight('flash_message',{duration:2.0});}
function checkConnection(){if(!connected){Element.update('flash_message','Unable to connect to push server, make sure flash is enabled for this site and SSL traffic is allowed...<br />You won\'t be able to see what others are saying.');Element.show('flash');new Effect.Highlight('flash_message',{duration:5.0,startcolor:'#ff9999'});}}
function decode64(input){var keyStr="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";var output="";var chr1,chr2,chr3;var enc1,enc2,enc3,enc4;var i=0;input=input.replace(/[^A-Za-z0-9\+\/\=]/g,"");do{enc1=keyStr.indexOf(input.charAt(i++));enc2=keyStr.indexOf(input.charAt(i++));enc3=keyStr.indexOf(input.charAt(i++));enc4=keyStr.indexOf(input.charAt(i++));chr1=(enc1<<2)|(enc2>>4);chr2=((enc2&15)<<4)|(enc3>>2);chr3=((enc3&3)<<6)|enc4;output=output+String.fromCharCode(chr1);if(enc3!=64){output=output+String.fromCharCode(chr2);}
if(enc4!=64){output=output+String.fromCharCode(chr3);}}while(i<input.length);return output;}
function utf8to16(str){var out,i,len,c;var char2,char3;out="";len=str.length;i=0;while(i<len){c=str.charCodeAt(i++);switch(c>>4)
{case 0:case 1:case 2:case 3:case 4:case 5:case 6:case 7:out+=str.charAt(i-1);break;case 12:case 13:char2=str.charCodeAt(i++);out+=String.fromCharCode(((c&0x1F)<<6)|(char2&0x3F));break;case 14:char2=str.charCodeAt(i++);char3=str.charCodeAt(i++);out+=String.fromCharCode(((c&0x0F)<<12)|((char2&0x3F)<<6)|((char3&0x3F)<<0));break;}}
return out;}
var lastElement=null;var lastPrefix=null;var lastColor=null;var tooltips=new Array;var tooltipids=new Array;var last_shout=null;var show_tooltips=1;function Hover(prefix,element){ClearHover();if($('edit'+'_'+prefix+'_'+element)){Element.show('edit'+'_'+prefix+'_'+element);}
lastColor=$(prefix+'_'+element).style.backgroundColor;$(prefix+'_'+element).style.backgroundColor="#fff2d4";lastElement=element;lastPrefix=prefix;}
function ClearHover(){if(lastElement!=null){if($('edit'+'_'+lastPrefix+'_'+lastElement)){Element.hide('edit'+'_'+lastPrefix+'_'+lastElement);}
$(lastPrefix+'_'+lastElement).style.backgroundColor=lastColor;}
lastElement=null;lastPrefix=null;}
function updateLoading(event){if($('loading').visible){scrollposY=0;if(window.pageYOffset){scrollposY=window.pageYOffset;}
else if(document.documentElement&&document.documentElement.scrollTop){scrollposY=document.documentElement.scrollTop}
else if(document.getElementById("body").scrollTop){scrollposY=document.getElementById("body").scrollTop;}
$("loading").style.top=(scrollposY+event.clientY-8)+"px";$("loading").style.left=event.clientX+10+"px";$("loading").style.zIndex=9;}}
Event.observe(window,"load",function(e){Event.observe(document,"mousemove",function(e){updateLoading(e);});});function tip(myEvent){var n=null;for(var i=0;i<tooltipids.length;i++){if(tooltipids[i]==Event.element(myEvent)){n=i;break;}}
if(n==null)
return;self.status=tooltips[n];scrollposY=0;if(window.pageYOffset){scrollposY=window.pageYOffset;}
else if(document.documentElement&&document.documentElement.scrollTop){scrollposY=document.documentElement.scrollTop}
else if(document.getElementById("body").scrollTop){scrollposY=document.getElementById("body").scrollTop;}
document.getElementById("message").innerHTML=tooltips[n];document.getElementById("tip").style.top=scrollposY+myEvent.clientY+15+"px";var left=myEvent.clientX-25;if(left<0)left=0;document.getElementById("tip").style.left=left+"px";document.getElementById("tip").style.zIndex=9;document.getElementById("tip").style.visibility="visible";}
function hide(e){document.getElementById("tip").style.visibility="hidden";self.status="ClockingIT v0.99";}
function makeTooltips(show){var a=document.getElementsByClassName('tooltip');for(var i=0;i<a.length;i++){if(show==1){tooltips[tooltips.length]=a[i].title;tooltipids[tooltipids.length]=a[i];Element.removeClassName(a[i],'tooltip');Event.observe(a[i],"mousemove",function(e){tip(e);});Event.observe(a[i],"mouseout",function(e){hide(e);});}
a[i].title='';}
Event.observe(document,"mousedown",function(e){hide(e);});show_tooltips=show;}
function updateTooltips(){var a=document.getElementsByClassName('tooltip');for(var i=0;i<a.length;i++){if(show_tooltips==1){tooltips[tooltips.length]=a[i].title;tooltipids[tooltipids.length]=a[i];Element.removeClassName(a[i],'tooltip');Event.observe(a[i],"mousemove",function(e){tip(e);});Event.observe(a[i],"mouseout",function(e){hide(e);});}
a[i].title='';}}
function init_shout(){if($('shout_body')){Event.observe($('shout_body'),"keypress",function(e){switch(e.keyCode){case Event.KEY_RETURN:if(e.shiftKey){return;}else{if($('shout_body').value.length>0){if(e.ctrlKey||e.metaKey){$('shout-input').onsubmit();$('shout_body').value='';}else{$('shout-input').onsubmit();$('shout_body').value='';}}
Event.stop(e);}}});}}
function inline_image(el){$(el).setStyle({width:'auto',visibility:'hidden'});if(el.width>500){el.style.width='500px';}
el.style.visibility='visible';}
function HideAjax(){var a=document.getElementsByClassName('ajax','div');for(var i=0;i<a.length;i++)
Element.hide(a[i]);}
function HideMenus(){var a=document.getElementsByClassName('amenu','div');for(var i=0;i<a.length;i++)
Element.hide(a[i]);}
function ShowMenus(){var a=document.getElementsByClassName('amenu','div');for(var i=0;i<a.length;i++)
Element.show(a[i]);}
function HideDummy(){}
function ShowDummy(){}
function UpdateDnD(){updateTooltips();}
function EnableDND(){Element.hide('enable_dnd');HideMenus();Sortable.create("components_sortable",{dropOnEmpty:true,handle:'handle_comp',onUpdate:function(){new Ajax.Request('/components/ajax_order_comp',{asynchronous:true,evalScripts:true,onComplete:function(request){Element.hide('loading');},onLoading:function(request){Element.show('loading');},parameters:Sortable.serialize("components_sortable")})},only:'component',tree:true});Sortable.create("tasks_sortable",{dropOnEmpty:true,handle:'handle',onUpdate:function(){new Ajax.Request('/components/ajax_order',{asynchronous:true,evalScripts:true,onComplete:function(request){Element.hide('loading');},onLoading:function(request){Element.show('loading');},parameters:Sortable.serialize("tasks_sortable")})},only:'task',tree:true});var h=document.getElementsByClassName('handle','img');;for(var i=0;i<h.length;i++){Element.show(h[i]);}
var h=document.getElementsByClassName('handle_comp','img');;for(var i=0;i<h.length;i++){Element.show(h[i]);}
Element.show('disable_dnd');}
function DisableDND(){Element.hide('disable_dnd');ShowMenus();var h=document.getElementsByClassName('handle','img');;for(var i=0;i<h.length;i++){Element.hide(h[i]);}
var h=document.getElementsByClassName('handle_comp','img');;for(var i=0;i<h.length;i++){Element.hide(h[i]);}
Element.show('enable_dnd');}
function do_update(user,url){if(user!=userId){new Ajax.Request(url,{asynchronous:true,evalScripts:true});}}
function do_execute(user,code){if(user!=userId){eval(code);}}
function enableControl(id,enabled){if(typeof(enabled)=="undefined")enabled=true;var control=$(id);if(!control)return;control.disabled=!enabled;}
function json_decode(txt){try{return eval('('+txt+')');}catch(ex){}}
function updateSelect(sel,response){response.evalScripts();var lines=response.split('\n');var obj=json_decode(lines[0]);sel.options.length=0;var opts=obj.options;for(var i=0;i<opts.length;i++){sel.options[i]=new Option(opts[i].text,opts[i].value,null,false);}}
function fixShortLinks(){$$('.task-name a').each(function(e){e.target='_blank';});$$('a.stop-work-link').each(function(e){if(e.href!='#'){Event.observe(e,"click",function(e){new Ajax.Request('/tasks/stop_work_shortlist',{asynchronous:true,evalScripts:true,onComplete:function(request){Element.hide('loading');},onLoading:function(request){Element.show('loading');}});return false;});e.href='#';}});}