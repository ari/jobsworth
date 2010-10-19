function new_project_file_callback(type) {
  jQuery('#file_upload_form').bind("ajax:success", function(event, json, xhr) {
    if (json.status == "error") {      
      jQuery("#flash").remove();
      jQuery(html_decode(json.message)).insertAfter("#tabmenu");
    } else {
      for (i=0;i<json.message.length;i++) {
        jQuery(html_decode(json.message[i].html)).insertAfter("#dir_sep");
        jQuery("#file_cell_" + json.message[i].id).effect("highlight", {}, 1000);
      }
      jQuery('#inline_form').hide();
    }
  }).bind("ajax:before", function(event, json, xhr) {
    showProgress();
  }).bind("ajax:complete", function(event, json, xhr) {
    hideProgress();
  });
}

function edit_file_callback(file_id) {
  jQuery('#edit_file_form').bind("ajax:success", function(event, html, xhr) {
    jQuery('#inline_form').hide();
    jQuery("#file_cell_" + file_id).replaceWith(html);
    jQuery("#file_cell_" + file_id).effect("highlight", {}, 2000);
  }).bind("ajax:before", function(event, html, xhr) {
    showProgress();
  }).bind("ajax:complete", function(event, html, xhr) {
    hideProgress();
  })
}

function new_project_file(type, id) {
  jQuery.ajax({
    url: '/project_files/new_'+ type +'?id='+ id,
    dataType: 'html',
    success:function(response) {
      jQuery('#inline_form').empty().prepend(response);
      jQuery('#inline_form').show();
      new_project_file_callback(type);
    },
    beforeSend: function(){ showProgress(); },
    complete: function(){ hideProgress(); },
    error:function (xhr, thrownError) {
      alert("Invalid request");
    }
  });
}

function edit_file(file_id) {
 jQuery.ajax({
    url: '/project_files/edit/'+ file_id,
    dataType: 'html',
    success:function(response) {
      jQuery('#inline_form').empty().prepend(response);
      jQuery('#inline_form').show();
      jQuery("#edit_file").effect("highlight", {}, 1000);
      edit_file_callback(file_id);
    },
    beforeSend: function(){ showProgress(); },
    complete: function(){ hideProgress(); },
    error:function (xhr, thrownError) {
      alert("Error :" + thrownError);
    }
  });
}

function remove_file(file_id, confirm_message) {
  var answer = confirm(confirm_message)
  if (answer){
    jQuery.ajax({
      url: '/project_files/destroy/'+ file_id,
      dataType: 'script',
      success:function(response) {
        jQuery('#file_cell_' + file_id).fadeOut('slow');
      },
      beforeSend: function(){ showProgress(); },
      complete: function(){ hideProgress(); },
      error:function (xhr, thrownError) {
        alert("Error : " + thrownError);
      }
    });
  }
}

function html_decode(value) {
  if(value=='&nbsp;' || value=='&#160;' || (value.length==1 && value.charCodeAt(0)==160)) { return "";}
  return !value ? value : String(value).replace(/&amp;/g, "&").replace(/&gt;/g, ">").replace(/&lt;/g, "<").replace(/&quot;/g, '"');
}

//drag and drop
jQuery(function() {
  jQuery(".cell_draggable" ).draggable({ revert: "invalid" });
  jQuery(".cell_droppable" ).droppable({
    tolerance: 'pointer',
    drop: function(event, ui) {
      var drop_id = jQuery(this).attr("id");
      var drag_id = jQuery(ui.draggable).attr("id");
      jQuery("#" + drag_id).remove();
      jQuery.get("/project_files/move?id=" + drag_id +" " + drop_id);
    }
  });
});