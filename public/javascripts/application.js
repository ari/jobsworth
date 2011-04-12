jQuery.noConflict();

// -------------------------
// theming
//

jQuery(function() {
  jQuery("input:submit").button();
  //jQuery("#tabmenu").tabs();
});



// -------------------------
// show progress spinner
//

function showProgress() {
  jQuery('#loading').show('fast');
}
function hideProgress() {
  jQuery('#loading').hide('fast');
}

jQuery(document).mousemove(function(e) {
  if (jQuery('#loading').is(':visible')) {
    jQuery("#loading").css({
      top: (e.pageY  - 8) + "px",
      left: (e.pageX + 10) + "px"
    });
  }
});

jQuery("#loading").bind("ajaxSend", function(){
   jQuery(this).show('fast');
 }).bind("ajaxComplete", function(){
   jQuery(this).hide('fast');
});



/*
 Tooltips are setup on page load, but sometimes the page is updated
 using ajax, and the tooltips need to be setup again, so this method
 sets up tooltips in page.
*/
function updateTooltips() {
    jQuery('.tooltip').tooltip({showURL: false });
}

function do_update(user, url) {
  if( user != userId ) {
      jQuery.get(url);
  }
}

function addProjectToUser(event, ui) {
    var value = ui.item.id;

    var url = document.location.toString();
    url = url.replace("/edit/", "/project/");
    jQuery.get(url, { project_id: value }, function(data) {
        jQuery("#add_user").before(data);
    });

    jQuery(this).val("");
    return false;
}

function addUserToProject(event, ui) {
    var value = ui.item.id;
    var url = document.location.toString();
    url = url.replace("/edit/", "/ajax_add_permission/");
    jQuery.get(url, { user_id : value }, function(data) {
        jQuery("#user_table").html(data);
    });
    return false;
}


/*
  Requests the available attributes for the given resource type
  and updates the page with the returned values.
*/
function updateResourceAttributes(select) {
    select = jQuery(select);
    var typeId = select.val();
    var target = jQuery("#attributes");

    if (typeId == "") {
        target.html("");
    }
    else {
        var url = "/resources/attributes/?type_id=" + typeId;
        jQuery.get(url, function(data) {
            target.html(data);
        });
    }
}

/*
  Removes the resource attribute to the link
*/
function removeAttribute(link) {
    link = jQuery(link);
    link.parent(".attribute").remove();
}

/*
  Adds a new field to allow people to have multiple values
  for resource attributes.
*/
function addAttribute(link) {
    link = jQuery(link);
    var origAttribute = link.parent(".attribute");

    var newAttribute = origAttribute.clone();
    newAttribute.find(".value").val("");
    newAttribute.find("a.add_attribute").remove();
    newAttribute.find(".attr_id").remove();

    var removeLink = newAttribute.find("a.remove_attribute");
    // for some reason this onclick needs to be manually set after cloning
    removeLink.click(function() { removeAttribute(removeLink); });
    removeLink.show();

    origAttribute.parent("#attributes").append(newAttribute);
}


// I'm not sure why, but we seem to need to add these for the event
// to fire - onclick doesn't seem to work.
jQuery(document).ready(function() {
    jQuery(".remove_attribute").click(function(evt) {
        removeAttribute(evt.target);
    });
});

/*
 Shows / hides applicabel attribute fields depending on the value
 of checkbox
*/
function updateAttributeFields(checkbox) {
    checkbox = jQuery(checkbox);
    var preset = checkbox.is(":checked");

    var parent = checkbox.parents(".attribute");
    var maxLength = parent.find(".max_length");
    var choices = parent.find(".choices");
    var choiceLink = parent.find(".add_choice_link");
    var multiple = parent.find(".multiple");

    if (preset) {
        multiple.hide().find("input").attr("checked", false);
        maxLength.hide().find("input").val("");
        choices.show();
        choiceLink.show();
    }
    else {
        multiple.show();
        maxLength.show();
        choices.hide().html("");
        choiceLink.hide();
    }
}

/*
  Does a get request to the given url. The response is appended
  to any element matching selector.
  If a callback function is given, that will be called after the partial
  has been loaded and added to the page.
*/
function appendPartial(url, selector, callback) {
    jQuery.get(url, { }, function(data) {
        jQuery(selector).append(data);

        if (callback) { callback.call(); }
    });
}

function appendPopup(url, selector, callback) {
    if (jQuery('span#ui_popup_dialog').size() == 0){
      jQuery.get(url, { }, function(data) {
        var html = "<span style='display: none' id='ui_popup_dialog'>"+ data +"</span>"
        jQuery(selector).prepend(html);
        if (callback) { callback.call(); }
      });
    }
}

function updatePositionFields(listSelector) {
    var list = jQuery(listSelector);
    var children = list.children();

    for (var i = 0; i < children.length; i++) {
        var positionField = jQuery(children[i]).find(".position");
        positionField.val(i + 1);
    }
}

/*
 Adds fields to setup a new custom attribute choice.
*/
function addAttributeChoices(sender) {
    var choices = jQuery(sender).parent().find('.choices');
    var callback = function() { updatePositionFields(choices); };

    var attribute = jQuery(sender).parents(".attribute");
    var attrId = attribute.attr("id").split("_").pop();

    if (attrId == "attribute") {
        // new attribute, so just ignore
        attrId = "";
    }
    var url = "/custom_attributes/choice/" + attrId;
    appendPartial(url, choices, callback);
}

/*
  Adds the selected dependency to the task currently being edited.
  The task must be saved for the dependency to be permanently linked.
*/
function addDependencyToTask(event, ui) {
    var id = ui.item.id;
    jQuery(this).val("");
    jQuery.get("/tasks/dependency/", { dependency_id : id }, function(data) {
        jQuery("#task_dependencies .dependencies").append(data);
    });
    return false;
}
/*
  Adds the selected resource to the task currently being edited.
  The task must be saved for the resource to be permanently linked.
*/
function addResourceToTask(event, ui) {
    var id = ui.item.id;
    jQuery(this).val("");
    jQuery.get("/tasks/resource/", { resource_id : id }, function(data) {
        jQuery("#task_resources").append(data);
    });
    return false;
}
/*
  Removes the link from resource to task
*/
function removeTaskResource(link) {
    link = jQuery(link);
    var parent = link.parent(".resource_no");
    parent.remove();
}

/*
  For the resources edit page.
  Retrieves the password from the given url, and updated
  the nearest password div with the returned value.
*/
function showPassword(link, url) {
    link = jQuery(link);
    link.hide();

    var passwordDiv = link.prev(".password");
    passwordDiv.load(url);
}

/*
  Checkboxes for nested forms cause trouble in params parsing
  when index => nil. This function fixes the problem by disabling the
  form element that is not in use.
*/
function nestedCheckboxChanged(checkbox) {
    checkbox = jQuery(checkbox);
    var checked = checkbox.attr("checked");

    var hiddenField = checkbox.prev();
    if (hiddenField.attr("name") == checkbox.attr("name")) {
                hiddenField.attr("disabled", checked);
    }
}

/*
    The function nestedCheckboxChanged will fix any
    checkboxes that are changed, but this function should be called
    on page load to fix any already in the page (generally because they
    failed a validation.
*/
function fixNestedCheckboxes() {
  var checkboxes = jQuery(".nested_checkbox");
  for (var i = 0; i < checkboxes.length; i++) {
    nestedCheckboxChanged(checkboxes[i]);
  }
}

/*
 Toggles the visiblity of the element next to sender.
 Updates the text of sender to "Show" or "Hide" as appropriate.
 Pass selector as null to just hide the immediately preceding element.
*/
function togglePreviousElement(sender, selector) {
    sender = jQuery(sender);
    var toggle = sender.prev();
    if (selector) {
        toggle = jQuery(selector);
    }

    if (toggle.is(':visible')) {
        sender.text("Show");
    }
    else {
        sender.text("Hide");
    }

    toggle.toggle();
}


/*
  Toggles the approval status of the given work log
*/
function toggleWorkLogApproval(sender, workLogId) {
    jQuery.post("/work_logs/update_work_log", {
        id : workLogId,
        "work_log[status]" : jQuery(sender).val() });
}

function setPageTarget(event, ui) {
    var id = ui.item.id;
    var type = ui.item.type;
    jQuery("#page_notable_id").val(id);
    jQuery("#page_notable_type").val(type);
}

/*TODO: Move following code to another file
*/
/*
  Attach behavior to views/tasks/_details.html.erb,
  instead of removed helper method task_project_watchers_js
*/
function attach_behaviour_to_project_select() {
  var projectSelect = jQuery('#task_project_id');
  if(projectSelect.size()){
    projectSelect.change(function(){
      projectId=jQuery('#task_project_id option:selected').val();
      refreshMilestones(projectId,0);
      addAutoAddUsersToTask('', '', projectId);
      addClientLinkForTask(projectId);
      if (projectId == "") {
        projectId = jQuery('#task_project_id option:nth-child(2)').attr('value');
      }
      jQuery('#add_milestone a').attr('href', '/milestones/new?project_id=' + projectId);
    });
  }
}

//return path to tasks or task_templates controller
//based on current page path
//so we can reuse tasks code, views and javasript in taks_templates
function tasks_path(action_name) {
  if (/tasks\//.test(document.location.pathname)) {
    return "/tasks/" + action_name ;
  }
  else if ( /task_templates\//.test(document.location.pathname)) {
    return "/task_templates/" + action_name ;
  }
  else if (jQuery('#template_clone').val() == '1') {
    return "/tasks/" + action_name ;
  }
  return action_name;
}


/*
 This function adds in the selected value to the previous autocomplete.
 The autocomplete text field itself will be updated with the name, and
 a hidden field directly before the text field will be updated with the object id.
*/
function updateAutoCompleteField(event, ui) {
    jQuery("#resource_customer_id").val(ui.item.id);
}

jQuery(document).ready(function() {
  fixNestedCheckboxes();

  highlightWatchers();
  init_task_form();

  jQuery(function() {
    jQuery('#target').catcomplete({
          source: '/pages/target_list',
          select: setPageTarget,
          delay: 800,
          minLength: 1
    });
  });
  autocomplete('#resource_customer_name', '/users/auto_complete_for_customer_name', updateAutoCompleteField);
  autocomplete('#project_customer_name', '/application/auto_complete_for_customer_name', addCustomerToProject);
  autocomplete('#user_project_name_autocomplete', '/users/auto_complete_for_project_name', addProjectToUser);
  autocomplete('#project_user_name_autocomplete', '/application/auto_complete_for_user_name', addUserToProject);
  autocomplete('#user_customer_name', '/users/auto_complete_for_customer_name', addCustomerToUser);

  jQuery(".datefield").datepicker({ constrainInput: false, dateFormat: userDateFormat});
});

function addCustomerToUser(event, ui){
  jQuery('#user_customer_id').val(ui.item.id);
}

function toggleAccess() {
  if (jQuery('#accessLevel_container div').hasClass('private')) {
    jQuery('#accessLevel_container div').removeClass('private');
    jQuery('#work_log_access_level_id').val('1');
    jQuery('#snooze_until').show();
  } else {
    jQuery('#accessLevel_container div').addClass('private');
    jQuery('#work_log_access_level_id').val('2');
    if(jQuery('#task_wait_for_customer').attr('checked')){
      jQuery('#snooze_until').hide();
    }
  }
  highlightWatchers();
}



function autocomplete(input_field, path, after_callback) {
  jQuery(input_field).autocomplete({source: path, select: after_callback, delay: 800, minLength: 3, search: showProgress, open: hideProgress});
}

jQuery.widget("custom.catcomplete", jQuery.ui.autocomplete, {
  _renderMenu: function( ul, items ) {
    var self = this,
      currentCategory = "";
    jQuery.each( items, function( index, item ) {
      if ( item.category != currentCategory ) {
        ul.append( "<li class='ui-autocomplete-category'>" + item.category + "</li>" );
        currentCategory = item.category;
      }
      self._renderItem( ul, item );
    });
  }
});




function autocomplete_multiple_remote(input_field, path){
    jQuery(function(){
        function split(val) {
                 return val.split(/,\s*/);
        }
        function extractLast(term) {
                 return split(term).pop();
                }
        jQuery(input_field).autocomplete({
            source: function(request, response) {
                                jQuery.getJSON(path, {
                                        term: extractLast(request.term)
                                }, response);
            },
            search: function() {
                                var term = extractLast(this.value);
                                if (term.length < 2) {
                                        return false;
                                }
                        },
            focus: function() {
                    return false;
            },
            select: function(event, ui) {
                    var terms = split( this.value );
                    terms.pop();
                    terms.push( ui.item.value );
                    terms.push("");
                    this.value = terms.join(", ");
                    return false;
            }

        });

     });

}


/* Events */
jQuery('#flash_message').click(function(){ jQuery('#flash').remove();});

jQuery('#worklog_body').blur(function(){
        jQuery.ajax({
                'url': '/tasks/updatelog',
                'data': jQuery('#worklog_form').serialize(),
                'dataType': 'text',
                'type': 'POST',
                'success': function(data){jQuery('#worklog-saved').html(data) ;}
        });
});

function mark_as_default(sender) {
   jQuery("label[for=user_email]").text("");
   jQuery(sender).parent().siblings("label").text("Email");
   jQuery("span#user_email_addresses span input[type=hidden]").val("");
   jQuery(sender).parent().siblings("input[type=hidden]").attr("value","1");
   jQuery("span#user_email_addresses span b").replaceWith("<span class='email_link_actions'><a class='action_email' href='#' onclick='mark_as_default(this); return false;'>Mark As Default</a><a class='action_email' href='#' onclick='jQuery(this).parent().parent().remove(); return false;'>Remove</a></span>");
   jQuery(sender).parent().parent().prependTo("span#user_email_addresses");
   jQuery(sender).parent().replaceWith("<b>Default</b>");
}

// Update the sheet at the top of the page every 90 seconds
//
jQuery(document).ready(function(){
  if (jQuery('#menu_info a').size()) {
    setInterval(function() {
      jQuery.get('/tasks/update_sheet_info', function(data) {
        jQuery('#menu_info').html(data);
      });
    },90 * 1000);
  }
});

function html_decode(value) {
  if(value=='&nbsp;' || value=='&#160;' || (value.length==1 && value.charCodeAt(0)==160)) { return "";}
  return !value ? value : String(value).replace(/&gt;/g, ">").replace(/&lt;/g, "<").replace(/&quot;/g, '"').replace(/&amp;/g, "&");
}

function flash_message(message) {
  jQuery("#flash").remove();
  jQuery(html_decode(message)).insertAfter("#tabmenu");
}

function authorize_ajax_form_callback(json) {
  if (json.status == "session timeout") {
    window.location = "/users/sign_in";
    return false;
  }
}

jQuery(document).ready(function(){
  jQuery('#page_snippet').change(switchTinyMCE);
});

function switchTinyMCE(){
    if (jQuery('#page_snippet:checked').size() == 1){
      if (!(typeof(tinyMCE)=='undefined')){
        tinyMCE.execCommand('mceRemoveControl', false, 'page_body');
      }
    }
    else{
      if(typeof(tinyMCE)=='undefined'){
        initTinyMCE();
      } else{
        tinyMCE.execCommand('mceAddControl', false, 'page_body');
      }
    }
}

function collapsiblePanel(panel) {
  if (getLocalStorage('sidepanel_' + panel) == 'h') {
    jQuery('div#' + panel +' .panel_content').hide();
    jQuery('div#' + panel +' .collapsable-sidepanel-button').addClass('panel-collapsed');
  } else {
    jQuery('div#' + panel +' .collapsable-sidepanel-button').addClass('panel-open');
  }
}

//functions to get, set and remove localStorage
//don't throw an error if browser doesn't support localStorage

function setLocalStorage(key, val) {
  if(typeof(localStorage) != 'undefined') {
    localStorage.setItem(key,val);
  }
}

function removeLocalStorage(key) {
  if(typeof(localStorage) != 'undefined') {
    localStorage.removeItem(key);
  }
}

function getLocalStorage(key) {
  if(typeof(localStorage) != 'undefined') {
    return localStorage.getItem(key);
  } else {
    return null;
  }
}

function isLocalStorageExist(key) {
  if (typeof(localStorage) != 'undefined') {
    return localStorage.key(key);
  } else {
    return false;
  }
}
jQuery(document).ready(function(){
  jQuery('.edit a.utility').click(function(){
    var href= jQuery(this).attr('href')
    var post_id= href.match(/posts\/(\d+)\/edit/)[1]
    if (!EditForm.isEditing(post_id)){
      EditForm.init(post_id);
        jQuery.ajax({url: href,
                     type: 'GET',
                     success: function(data){
                        jQuery("#edit").replaceWith(data);
                        EditForm.setReplyId(post_id);
                        jQuery("#edit-post-" + post_id + "_spinner").hide();
                        jQuery("#edit_post_body").focus().delay(250);
                      }
        });
    }
    return false;
  });
});
