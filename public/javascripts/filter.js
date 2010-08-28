/*
Submits the search filter form. If we are looking at the task list,
does that via ajax. Otherwise does a normal html post
*/
function submitSearchFilterForm() {
  var form = jQuery("#search_filter_form")[0];
  var redirect = jQuery(form.redirect_action).val();
  if (redirect.indexOf("/tasks/list") >= 0) {
    form.onsubmit();
  }
  else {
    form.submit();
  }
}

/*
Removes the search filter the link belongs to and submits
the containing form.
*/
function removeSearchFilter(link) {
  link = jQuery(link);
  link.parent().parent("li").remove();
  submitSearchFilterForm();
}

function reverseSearchFilter(link){
  input = jQuery(link).siblings("input.reversed");
  if (input.val() == "false") {
    input.val("true");
  } else {
    input.val("false");
  }
  submitSearchFilterForm();
}

/* This function add inputs to search filter form, it works in both cases via normal http post and via ajax
*/
function addSearchFilter(event, ui) {
    selected = ui.item;
    var idName = selected.id;
    var idValue = selected.idval;
    /*NOTE: if user select qulifier, than idName -> name of param qualifier_id
      idValue -> value of this param, etc.
      else if user select keyword, then idName -> name of keyword_id or unread_only  param, idValue-> value of  param,
      but type&column name/value not exist
    */
    var typeName = selected.type;
    var typeValue = selected.typeval;
    var columnName = selected.col;
    var columnValue = selected.colval;
    var reversedName = selected.reversed;
    var reversedVal = selected.reversedval;
    if (idName && idName.length > 0) {
        var filterKeys = jQuery("#search_filter_form ul#search_filter_keys");
        filterKeys.append('<input type="hidden" name="'+idName+'" value="'+idValue+'"/>');
        if (typeName && typeName.length>0){
            filterKeys.append('<input type="hidden" name="'+typeName+'" value="'+typeValue+'"/>');
        }
        if (columnName && columnName.length>0) {
            filterKeys.append('<input type="hidden" name="'+columnName+'" value="'+columnValue+'"/>');
        }
        if (reversedName && reversedName.length > 0) {
            filterKeys.append('<input type="hidden" name="'+reversedName+'" value="'+reversedVal+'"/>');
        }
        submitSearchFilterForm();
    } else {
                // probably selected a heading, just ignore
    }
    jQuery(this).val("");
    return false;
}

function removeTaskFilter(sender) {
  var li = jQuery(sender).parent();
  var form = li.parents("form");
  li.remove();
  form.submit();
}

function addTaskFilter(sender, id, field_name) {
  var li = jQuery(sender);
  var html = "<input type='hidden' name='" + field_name + "' value='" + id + "' />";
  li.append(html);
  jQuery("#filter_form").submit();
}

jQuery(document).ready(function() {
  // make search box contents selected when the user clicks in it
  jQuery("#search_filter").focus( function() {
    if (jQuery(this).val() == "Task search...") {
      jQuery(this).val('').removeClass('grey');
    } else {
      jQuery(this).select();
    }
  });

  jQuery("#search_filter").blur( function() {
      if (jQuery(this).val() == '') {
          jQuery(this).val("Task search...").addClass('grey');
      }
  });

  // the user/client search box
  jQuery(".search_filter").focus( function() {
    jQuery(this).select();
  });

  // Go to a task immediately if a number is entered and then the user hits enter
  jQuery("#search_filter").keypress(function(key) {
    if (key.keyCode == 13) { // if key was enter
      var id = jQuery(this).val();
      if (id.match(/^\d+$/)) {
        loadTask(id);
      }
    }
  });
});