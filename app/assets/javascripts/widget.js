function widget_toggle_display(widget_id) {
  jQuery.ajax({
    url: '/widgets/toggle_display/' + widget_id,
    dataType: 'json',
    success:function(response) {
      if (response.collapsed) {
        jQuery("#content_" + response.dom_id).hide();
        jQuery("#indicator-" + response.dom_id).attr("class", "widget-collapsed");
      }
      else {
        jQuery("#content_" + response.dom_id).show();
        jQuery("#indicator-" + response.dom_id).attr("class", "widget-open");
      }
      portal.refreshHeights();
    },
    beforeSend: function(){ showProgress(); },
    complete: function(){ hideProgress(); },
    error:function (xhr, thrownError) {
      alert("Invalid request");
    }
  });
}

function edit_widget(id, dom_id) {
  jQuery.ajax({
    url: '/widgets/edit/' + id,
    dataType: 'html',
    success:function(response) {
      if(!jQuery('#config-' + dom_id).size() ) {
        jQuery(response).insertBefore('#content_' + dom_id);
        jQuery('#config-' + dom_id).fadeIn('slow');
        update_widget_callback(id, dom_id);
      } else {
        jQuery('#config-' + dom_id).fadeOut('slow');
        jQuery('#config-' + dom_id).remove().delay(1000);
      }
    },
    beforeSend: function(){ showProgress(); },
    complete: function(){ hideProgress(); },
    error:function (xhr, thrownError) {
      alert("Invalid request");
    }
  });
}

function update_widget_callback(id, dom_id) {
  jQuery('#update_widget_' + id).bind("ajax:success", function(event, response, xhr) {
    var json = JSON.parse(response);
    authorize_ajax_form_callback(json);
    jQuery("#config-" + dom_id).remove();
    jQuery("#name-" + dom_id).replaceWith(json.widget_name);
    show_widget(id, dom_id, json.widget_type, json.configured, json.gadget_url);
  }).bind("ajax:before", function(event, json, xhr) {
    showProgress();
  }).bind("ajax:complete", function(event, json, xhr) {
    hideProgress();
  });
}

function show_widget(id, dom_id, type, configured, gadget_url) {
  jQuery.ajax({
    url: '/widgets/show/' + id,
    dataType: 'html',
    success:function(response) {
      if (configured == true) {
        jQuery("#content_" + dom_id).html(response);
        if (type == 8) {
          document.write = function(s) {
            jQuery('#gadget-wrapper-' + dom_id).innerHTML += s;
          }
          var e = new Element('script', {id:'gadget-' + dom_id});
          jQuery('#gadget-wrapper-' + dom_id).prepend(e);
          jQuery('#gadget-' + dom_id).attr('src', gadget_url.gsub(/&amp;/,'&').gsub(/<script src=/,'').gsub(/><\/script>/,''));
        }
        updateTooltips();
        portal.refreshHeights();
      } else {
         jQuery(response).insertBefore("#content_" + dom_id);
         jQuery('#config-' + dom_id).show('slow');
         jQuery("#content_" + dom_id + ' span.optional').replaceWith("<span class='optional'><br/>'Please configure the widget'</span>");
      }
    },
    beforeSend: function(){ showProgress(); },
    complete: function(){ hideProgress(); },
    error:function (xhr, thrownError) {
      jQuery("#content_" + dom_id).replaceWith("<span class='optional'><br/>Loading <b>" + jQuery("#name-widgets-" + id).html() +"</b> Failed</span>");
    }
  });
}

function add_widget() {
  if(! jQuery('#add-widget').length ) {
    jQuery.ajax({
      url: '/widgets/add',
      dataType: 'html',
      success:function(response) {
        jQuery('#left_col').prepend(response);
        jQuery("#add-widget").fadeIn("slow");
      },
      beforeSend: function(){ showProgress(); },
      complete: function(){ hideProgress(); },
      error:function (xhr, thrownError) {
        alert("Invalid request");
      }
    });
  } else {
    jQuery("#add-widget").fadeOut("slow");
  }
}

// functions for 'Projects' widget
function toggle_projects(id, toggle) {
    toggle_projects_widget(id, toggle, 'project_', '#projects_customer_', '#indicator_', 'collapse-indicator-');
}
function toggle_milestones(id, toggle){
    toggle_projects_widget(id, toggle, 'milestone_', 'tr.project_', '#small_indicator_', 'small-collapse-indicator-');
}
function toggle_projects_widget(id, toggle, cookie_prefix, container_prefix, indicator_prefix, class_prefix)
{
    var collapsed = jQuery.cookie(cookie_prefix + id);
    collapsed = (collapsed == 'true' ? true : false);
    if(toggle) { collapsed = !collapsed; }
    jQuery.cookie(cookie_prefix + id, (collapsed ? 'true' : null));
    if (collapsed) {
        jQuery(container_prefix + id).hide();
        jQuery(indicator_prefix + id).attr('class', class_prefix  + 'closed');
    } else {
        jQuery(container_prefix + id).show();
        jQuery(indicator_prefix + id).attr('class', class_prefix + 'open');
    }
}

function init_projects_widget(){
    if (document.cookie && document.cookie != '') {
        jQuery.each(document.cookie.match(/milestone_[0-9]+/g), function(index, key){
            toggle_milestones(key.split('_')[1], false)
        });
        jQuery.each(document.cookie.match(/project_[0-9]+/g), function(index, key){
            toggle_projects(key.split('_')[1], false)
        });
    }
}
