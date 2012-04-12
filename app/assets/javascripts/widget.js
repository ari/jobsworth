var jobsworth = jobsworth || {};

jobsworth.Portal = (function() {
  var $ = jQuery;

  function Portal(options) {
    this.options = options;
    this.bindEvents();
  }

  Portal.prototype.bindEvents = function() {
    var self = this;

    // sortable
    $("#widget-container .column" ).sortable({
      connectWith: ".column",
      placeholder: "widget-placeholder"
    });
    $("#widget-container .column").disableSelection();

    // reorder events
    $("#widget-container .column").live("sortupdate", function(event, ui) {
      var orders = [];
      $("#widget-container .column").each(function(index, column) {
        orders[index] = [];
        $(".widget", column).each(function(position, widget) {
          orders[index][position] = $(widget).data("widget-id");
        })
      })

      $.post("/widgets/save_order", {order:orders});
    })

    $(".widget").live("hover", function() {
      if ($(this).is(":hover")) {
        $(".widget-menu", this).removeClass("hide");
      } else {
        $(".widget-menu", this).addClass("hide");
      }
    })

    $(".widget a.delete").live("click", function() {
      var widget = $(this).parents(".widget");
      var widget_id = widget.data("widget-id");
      if( !confirm('Really delete widget?') ) return false;

      $.get('/widgets/destroy/' + widget_id, function(data){
        if (data.success) {
          widget.fadeOut("slow");
          widget.remove();
        } else {
          alert("delete widget failed.");
        }
      });
      return false;
    })

    $(".widget a.edit").live("click", function() {
      var widget_id = $(this).parents(".widget").data("widget-id");
      var widget_dom_id = $(this).parents(".widget").data("widget-dom-id");
      self.edit_widget(widget_id, widget_dom_id);
      return false;
    })

    $(".widget a.toggle-display").live("click", function() {
      var widget_id = $(this).parents(".widget").data("widget-id");
      self.widget_toggle_display(widget_id);
      return false;
    })

    $("#add-widget-menu-link").bind("click", function() {
      self.add_widget();
      return false;
    })

    $("form#add_widget").bind("ajax:success", function(event, response, xhr) {
      if (!response.success) {
        alert("create widget failed.");
        return;
      }

      $("#add-widget").addClass("hide");
      $("#widget-container .column").first().append(response.html);
      self.show_widget(response.widget.id, response.widget.dom_id, response.widget.widget_type, response.widget.configured, response.widget.gadget_url);
    })
  }

  Portal.prototype.widget_toggle_display = function(widget_id) {
    $.ajax({
      url: '/widgets/toggle_display/' + widget_id,
      dataType: 'json',
      success:function(response) {
        if (response.collapsed) {
          $("#content_" + response.dom_id).hide();
          $("#indicator-" + response.dom_id).removeClass("widget-open");
          $("#indicator-" + response.dom_id).addClass("widget-collapsed");
        }
        else {
          $("#content_" + response.dom_id).show();
          $("#indicator-" + response.dom_id).removeClass("widget-collapsed");
          $("#indicator-" + response.dom_id).addClass("widget-open");
        }
      },
      beforeSend: function(){ showProgress(); },
      complete: function(){ hideProgress(); },
      error:function (xhr, thrownError) {
        alert("Invalid request");
      }
    });
  }

  Portal.prototype.edit_widget = function(id, dom_id) {
    var self = this;
    $.ajax({
      url: '/widgets/edit/' + id,
      dataType: 'html',
      success:function(response) {
        if(!$('#config-' + dom_id).size() ) {
          $(response).insertBefore('#content_' + dom_id);
          $('#config-' + dom_id).fadeIn('slow');
          self.update_widget_callback(id, dom_id);
        } else {
          $('#config-' + dom_id).fadeOut('slow');
          $('#config-' + dom_id).remove().delay(1000);
        }
      },
      beforeSend: function(){ showProgress(); },
      complete: function(){ hideProgress(); },
      error:function (xhr, thrownError) {
        alert("Invalid request");
      }
    });
  }

  Portal.prototype.update_widget_callback = function(id, dom_id) {
    var self = this;
    $('#update_widget_' + id).bind("ajax:success", function(event, response, xhr) {
      var json = response;
      authorize_ajax_form_callback(json);
      $("#config-" + dom_id).remove();
      $("#name-" + dom_id).replaceWith(json.widget_name);
      self.show_widget(id, dom_id, json.widget_type, json.configured, json.gadget_url);
    }).bind("ajax:before", function(event, json, xhr) {
      showProgress();
    }).bind("ajax:complete", function(event, json, xhr) {
      hideProgress();
    });
  }

  Portal.prototype.show_widget = function(id, dom_id, type, configured, gadget_url) {
    $.ajax({
      url: '/widgets/show/' + id,
      dataType: 'html',
      success:function(response) {
        if (configured == true) {
          $("#content_" + dom_id).html(response);
          if (type == 8) {
            document.write = function(s) {
              $('#gadget-wrapper-' + dom_id).innerHTML += s;
            }
            var e = new Element('script', {id:'gadget-' + dom_id});
            $('#gadget-wrapper-' + dom_id).prepend(e);
            $('#gadget-' + dom_id).attr('src', gadget_url.gsub(/&amp;/,'&').gsub(/<script src=/,'').gsub(/><\/script>/,''));
          }
        } else {
           $(response).insertBefore("#content_" + dom_id);
           $('#config-' + dom_id).show('slow');
           $("#content_" + dom_id + ' span.optional').replaceWith("<span class='optional'>'Please configure the widget'</span>");
        }
      },
      beforeSend: function(){ showProgress(); },
      complete: function(){ hideProgress(); },
      error:function (xhr, thrownError) {
        $("#content_" + dom_id).replaceWith("<span class='optional'><br/>Loading <b>" + $("#name-widgets-" + id).html() +"</b> Failed</span>");
      }
    });
  }

  Portal.prototype.add_widget = function() {
    $('#add-widget').removeClass("hide");
  }

  return Portal;
})();


