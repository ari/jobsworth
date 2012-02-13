function new_project_file_callback(type) {
  jQuery('#file_upload_form').bind("ajax:success", function(event, json, xhr) {
    if (type == 'folder') {var json = JSON.parse(json);}
    if (json.status == "error") {
      flash_message(json.message);
    } else {
      if (type == 'file') {
        for (i=0;i<json.message.length;i++) {
          jQuery(html_decode(json.message[i].html)).insertAfter("#dir_sep");
          jQuery("#file_cell_" + json.message[i].id).effect("highlight", {}, 1000);
        }
      } else {
        jQuery(html_decode(json.html)).insertBefore("#dir_sep");
      }
      jQuery('#inline_form').hide();
      init_drag_drop();
    }
  }).bind("ajax:before", function(event, json, xhr) {
    showProgress();
  }).bind("ajax:complete", function(event, json, xhr) {
    hideProgress();
  });
}

function edit_file_callback(type, file_id) {
  jQuery('#edit_file_form').bind("ajax:success", function(event, response, xhr) {
    var json = response;
    if (json.status == 'success') {
      jQuery('#inline_form').hide();
      jQuery("#"+ type +"_cell_" + file_id).replaceWith(json.html);
      jQuery("#"+ type +"_cell_" + file_id).effect("highlight", {}, 2000);
      init_drag_drop();
    } else {
      flash_message(json.html);
    }
  }).bind("ajax:before", function(event, response, xhr) {
    showProgress();
  }).bind("ajax:complete", function(event, response, xhr) {
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

function edit_file(type, file_id) {
 jQuery.ajax({
    url: '/project_files/edit_'+ type + '/'+ file_id,
    dataType: 'html',
    success:function(response) {
      jQuery('#inline_form').empty().prepend(response);
      jQuery('#inline_form').show();
      jQuery("#edit_" + type).effect("highlight", {}, 1000);
      edit_file_callback(type, file_id);
    },
    beforeSend: function(){ showProgress(); },
    complete: function(){ hideProgress(); },
    error:function (xhr, thrownError) {
      alert("Error :" + thrownError);
    }
  });
}

function remove_file(type, file_id, confirm_message) {
  var answer = confirm(confirm_message)
  if (answer){
    jQuery.ajax({
      url: '/project_files/destroy_'+ type +'/'+ file_id,
      dataType: 'json',
      success:function(response) {
        if (response.status == 'success') {
          jQuery('#' + type +'_cell_' + file_id).fadeOut('slow');
        } else {
          flash_message(response.message);
        }
      },
      beforeSend: function(){ showProgress(); },
      complete: function(){ hideProgress(); },
      error:function (xhr, thrownError) {
        alert("Error : " + thrownError);
      }
    });
  }
}

//drag and drop
function init_drag_drop() {
  jQuery(".cell_draggable" ).draggable({ revert: "invalid" });
  jQuery(".cell_droppable" ).droppable({
    tolerance: 'pointer',
    drop: function(event, ui) {
      var drop_id = jQuery(this).attr("id");
      var drag_id = jQuery(ui.draggable).attr("id");
      jQuery("#" + drag_id).remove();
      jQuery.ajax({
        url: "/project_files/move?id=" + drag_id +" " + drop_id,
        dataType: 'html',
        success:function(response) {
          jQuery("#"+ drop_id).replaceWith(response);
        },
        beforeSend: function(){ showProgress(); },
        complete: function(){ hideProgress(); },
        error:function (xhr, thrownError) {
          alert("Moving folder/file failed");
        }
      });
    }
  });
}

jQuery(function() {
  init_drag_drop();
});
