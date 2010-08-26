jQuery.noConflict();

var lastElement = null;
var lastPrefix = null;
var lastColor = null;
var show_tooltips = 1;
var fetchTimeout = null;
var fetchElement = null;


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
        if(jQuery('#loading').is(':visible')) {
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

function inline_image(el) {
  $(el).setStyle({width:'auto', visibility:'hidden'});
  if (el.width > 500) {
    el.style.width = '500px';
  }
  el.style.visibility = 'visible';
}

/*
 Tooltips are setup on page load, but sometimes the page is updated
 using ajax, and the tooltips need to be setup again, so this method
 sets up tooltips in page.
*/
function updateTooltips() {
    jQuery('.tooltip').tooltip({showURL: false });
}

function UpdateDnD() {
  updateTooltips();
}

function do_update(user, url) {
  if( user != userId ) {
      jQuery.get(url);
  }
}

function rebuildSelect(select, data) {
   select.options.length = 0;
   for( var i=0; i<data.length; i++ ) {
     select.options[i] = new Option(data[i].text,data[i].value,null,false);
   }
}

// refresh the milestones select menu for all milestones from project pid, setting the selected milestone to mid
// also old /milestones/get_milestones returns line of javasript code `jQuery('#add_milestone').[show()|hide]`
// new /milestones/get_milestones returns flag add_milestone_visible
function refreshMilestones(pid, mid) {
  jQuery.getJSON("/milestones/get_milestones", {project_id: pid},
        function(data) {
                var milestoneSelect = jQuery('#task_milestone_id').get(0);
                rebuildSelect(milestoneSelect, data.options);
                milestoneSelect.options[mid].selected = true;
                if(data.add_milestone_visible){
                  jQuery('#add_milestone').show();
                }else{
                  jQuery('#add_milestone').hide();
                }
  });
}

function dateToWords(elem) {
    var date = elem.text();
    var text = date;
    var className = null;

    date = jQuery.datepicker.parseDate("yy-mm-dd", date);

    if (date !== null) {
        var diff = (((new Date()).getTime() - date.getTime()) / 1000);
        var dayDiff = Math.floor(diff / 86400);

        if (isNaN(dayDiff)) {
            text = date;
        }
        else if (dayDiff == -1) {
            text = "Tomorrow";
            className = "due_tomorrow";
        }
        else if (dayDiff === 0) {
            text = "Today";
            className = "due";
        }
        else if (dayDiff == 1) {
            text = "Yesterday";
            className = "due_overdue";
        }
        else if (dayDiff < 0) {
            dayDiff = Math.abs(dayDiff);
            text = dayDiff + " days";
            className = dayDiff >= 7 ? "due_distant" : "due_soon";
        }
        else if (dayDiff > 0) {
            text = dayDiff + " days ago";
            className = "due_overdue";
        }
    }

    elem.addClass(className);
    elem.text(text);
}

jQuery.fn.dateToWords = function() {
    return this.each(function() {
                dateToWords(jQuery(this));
    });
};


/*
 Marks the task sender belongs to as unread.
 Also removes the "unread" class from the task html.
 If userId is given, that will be sent too.
 */
function toggleTaskUnread(event, userId) {
    var task = jQuery(event.target).parents(".task");

    var unread = task.hasClass("unread");
    task.toggleClass("unread");

    var taskId = task.attr("id").replace("task_row_", "");
    taskId = taskId.replace("task_", "");
    var parameters = { "id" : taskId, "read" : unread };
    if (userId) {
        parameters.user_id = userId;
    }

    jQuery.post(tasks_path("set_unread"),  parameters);

    event.stopPropagation();
    return false;
}

/*
 Clears the text in the given field
*/
function clearPrompt(field) {
    field.value = "";
}


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
    if(input.val() == "false"){
        input.val("true");
    }else {
        input.val("false");
    }
    submitSearchFilterForm();
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


/*
Sets up the search filter input field to add a task automatically
if a number is entered and then the user hits enter
*/
function addSearchFilterTaskIdListener() {
    var filter = jQuery("#search_filter");
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
 This function adds in the selected value to the previous autocomplete.
 The autocomplete text field itself will be updated with the name, and
 a hidden field directly before the text field will be updated with the object id.
*/
function updateAutoCompleteField(event, ui) {
    jQuery("#resource_customer_id").val(ui.item.id);
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

    origAttribute.after(newAttribute);
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

/* FILTER METHODS */

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

/* TASK OWNER METHODS */
function removeTaskUser(sender) {
    sender = jQuery(sender);
    sender.parent(".watcher").remove();
    highlightWatchers();
}

function toggleTaskIcon(sender) {
    var div = jQuery(sender).parents(".watcher");

    var input = div.find("input.assigned");
    var icon = div.find(".icon.assigned");

    if (input.attr("disabled")) {
        div.addClass("is_assigned");
        input.attr("disabled", false);
    }
    else {
        input.attr("disabled", true);
        div.removeClass("is_assigned");
    }
}

/*
  Adds the selected user to the current tasks list of users
*/
function addUserToTask(event, ui) {
    var userId = ui.item.id;
    var taskId = jQuery("#task_id").val();
    var url = tasks_path('add_notification');
    var params = { user_id : userId, id : taskId };
    addUser(url, params);
    jQuery(this).val("");
    return false;

}


/*
  Adds any users setup as auto add to the current task.
*/
function addAutoAddUsersToTask(clientId, taskId, projectId) {
    var url = tasks_path("add_users_for_client");
    var params = { client_id : clientId, id : taskId, project_id : projectId };
    addUser(url, params);
}

function addUser(url, params){
    jQuery.get(url, params, function(data) {
        jQuery("#task_notify").append(data);
        highlightWatchers();
    });
}
/*
  Adds the selected customer to the current task list of clients
*/
function addCustomerToTask(event, ui) {
    var clientId = ui.item.id;
    var taskId = jQuery("#task_id").val();

    var url = tasks_path("add_client");
    var params = { client_id : clientId, id : taskId };
    jQuery.get(url, params, function(data) {
                jQuery("#task_customers").append(data);
    });

    addAutoAddUsersToTask(clientId, taskId);
    jQuery(this).val("");
    return false;
}
/*Adds the selected customer to the new project*/
function addCustomerToProject(event, ui){
    jQuery('#project_customer_id').val(ui.item.id);
}
/*
  If this task has no linked clients yet, link the one that
  project belongs to and update the display.
*/
function addClientLinkForTask(projectId) {
    var customers = jQuery("#task_customers").text();

    if (jQuery.trim(customers) == "") {
        var url = tasks_path("add_client_for_project");
        var params = { project_id : projectId };
        jQuery.get(url, params, function(data) {
            jQuery("#task_customers").html(data);
        });
    }
}

/*
  Toggles the approval status of the given work log
*/
function toggleWorkLogApproval(sender, workLogId) {
    var checked = jQuery(sender).attr("checked");

    jQuery.post("/tasks/update_work_log", {
        id : workLogId,
        "work_log[approved]" : checked });
}

// TODOS

/*
Toggles the todo display or edit fields
*/
function toggleTodoEdit(sender) {
    var todo = jQuery(sender).parents(".todo");
    var display = todo.find(".display");
    var edit = todo.find(".edit");

    display.toggle();
    edit.toggle();
}

/*
Adds listeners to handle users pressing enter in the todo
edit field
*/
function addTodoKeyListener(todoId, taskId) {
    var todo = jQuery("#todos-" + todoId);
    var input = todo.find(".edit input");

    input.keypress(function(key) {
        if (key.keyCode == 13) {
            jQuery(".todo-container").load("/todos/update/" + todoId,  {
                "_method": "PUT",
                task_id: taskId,
                "todo[name]": input.val()
            });

            key.stopPropagation();
            return false;
        }
    });
}

function addTodoCloneKeyListener(positionId) {
    var todo = jQuery("#todos-" + positionId);
    var input = todo.find(".edit input");

    input.keypress(function(key) {
        if (key.keyCode == 13) {
            jQuery(".todo-container").load("/todos/update_clone/" + positionId,  {
                "_method": "PUT",
                "todo[name]": input.val()
            });

            key.stopPropagation();
            return false;
        }
    });
}

/*
Adds listeners to handle users pressing enter in the todo
create field
*/
function addNewTodoKeyListener(taskId) {
    var todo = jQuery("#new-todos");
    var input = todo.find(".edit input");

    input.keypress(function(key) {
        if (key.keyCode == 13) {
            jQuery(".todo-container").load("/todos/create", {
                "_method": "POST",
                task_id: taskId,
                "todo[name]": input.val()
            });

            key.stopPropagation();
            return false;
        }
    });
}

function addNewTodoCloneKeyListener() {
    var todo = jQuery("#new-todos");
    var input = todo.find(".edit input");

    input.keypress(function(key) {
        if (key.keyCode == 13) {
            jQuery(".todo-container").load("/todos/create_clone", {
                "_method": "POST",
                "todo[name]": input.val()
            });

            key.stopPropagation();
            return false;
        }
    });
}

function setPageTarget(event, ui) {
    var id = ui.item.id;
    var type = ui.item.type;
    jQuery("#page_notable_id").val(id);
    jQuery("#page_notable_type").val(type);
}

jQuery(document).ready(function() {
    fixNestedCheckboxes();
});

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
      jQuery('#add_milestone a').attr('href', '/milestones/quick_new?project_id=' + projectId);
    });
  }
}
/*Attach behavior to filters panel,
  change filter via ajax only on task/list page.
  On all other pages, when user click on filter link change filter
*/
function initFiltersPanel() {
  jQuery('div.task_filters ul li a').click(loadFilterPanel);
}

function initTagsPanel() {
  jQuery('#tags a').click(loadFilterPanel);
}

function loadFilterPanel() {
  jQuery('#search_filter_keys').effect("highlight", {color: '#FF9900'}, 3000);
  jQuery.ajax({
            beforeSend: function(){ showProgress(); },
            complete: function(request){ tasklistReload(); hideProgress(); } ,
            data:'',
            success:  function(request){jQuery('#search_filter_keys').html(request);},
            type:'post',
            url: this.href
        });
        return false;
}

jQuery(document).ready(function() {
    //only if we on task list page
    if( /tasks\/list$/.test(document.location.href) ){
        initFiltersPanel();
        initTagsPanel();
    }
});


//return path to tasks or task_templates controller
//based on current page path
//so we can reuse tasks code, views and javasript in taks_templates
function tasks_path(action_name) {
    if(/tasks\//.test(document.location.pathname)) {
        return "/tasks/" + action_name ;
    }
    else if ( /task_templates\//.test(document.location.pathname)) {
            return "/task_templates/" + action_name ;
    }
    else if(jQuery('#template_clone').val() == '1') {
            return "/tasks/" + action_name ;
        }
    return action_name;
}

/*
This function simulate two step user behavior in one click
First goto template edit page, see template in form
Second send template form attributes to tasks/new
*/

function create_task_from_template(event) {
    jQuery.get('/task_templates/edit/'+jQuery(this).attr('data-tasknum')+'.js', function(data) {
        var form=jQuery(data).first();
        form.attr('action','/tasks/create');
        form.attr('id','taskform');
        jQuery('#main_col').html(form);
        jQuery('#taskform').append('<input type="hidden" id="template_clone" value="1" />');
        jQuery('.todo-container').load('/todos/list_clone/' + jQuery("#task_id").val());
        jQuery('.task-todo').attr("id", "todo-tasks-clone");
        jQuery('#task_id').removeAttr('value');
        jQuery('ul#primary > li').removeClass('active');
        jQuery('li.task_template').parent().parent().addClass('active');
        jQuery('#work-log').prevAll().remove();
        jQuery('#task_sidebar > small > a').attr('href', '/tasks/edit/0').text('#0');
        jQuery('#task_sidebar > small > span').remove();
        jQuery("#due_at").datepicker({ constrainInput: false, dateFormat: 'dd/mm/yy' });
        jQuery("#flash").remove();
        highlightWatchers();
        init_task_form();
        attachObseverForWorkLog();
    });
}

function attachObseverForWorkLog() {
	jQuery('#worklog_body').blur(function(){
		jQuery.ajax({
			'url': '/tasks/updatelog',
			'data': jQuery('#worklog_form').serialize(),
			'dataType': 'text',
			'type': 'POST',
			'success': function(data){jQuery('#worklog-saved').html(data) ;}
		});
	});
}

jQuery(document).ready(function() {
    jQuery('li.task_template a').click(create_task_from_template);
    highlightWatchers();  /* run this once to initialise everything right */
    init_task_form();
    attachObseverForWorkLog();
    if ( /task_templates\//.test(document.location.pathname)) {
       hide_unneeded_inputs_for_task_template();
    }
    jQuery('#flash_message').click(function(){ jQuery('#flash').remove();});
    jQuery(function() {
        jQuery('#target').catcomplete({
              source: '/pages/target_list',
              select: setPageTarget,
              delay: 800,
              minLength: 1
        })
    });
    autocomplete('#resource_customer_name', '/users/auto_complete_for_customer_name', updateAutoCompleteField);
    autocomplete('#project_customer_name', '/projects/auto_complete_for_customer_name', addCustomerToProject);
    autocomplete('#project_name', '/users/auto_complete_for_project_name', addProjectToUser);
    autocomplete('#project_user_name_autocomplete', '/projects/auto_complete_for_user_name', addUserToProject);
});

function toggleAccess() {
        if (jQuery('#accessLevel_container div').hasClass('private')) {
                jQuery('#accessLevel_container div').removeClass('private');
                jQuery('#work_log_access_level_id').val('1');
        } else {
                jQuery('#accessLevel_container div').addClass('private');
                jQuery('#work_log_access_level_id').val('2');
    }
        highlightWatchers();
}

function highlightWatchers() {
        if (jQuery('#comment').val() == '') {
                jQuery('.watcher').removeClass('will_notify');
                jQuery('#notify_users').html('');
        } else {
                if (jQuery('#accessLevel_container div').hasClass('private')) {
                        jQuery('.watcher').removeClass('will_notify');
                        jQuery('.watcher.access_level_2').addClass('will_notify');
                } else {
                        jQuery('.watcher').addClass('will_notify');
                }
                var watcher = "Notify: ";
                jQuery('div.watcher.will_notify a.username span').each(function() {
                        watcher = watcher + jQuery(this).html() + ", ";
                });
                jQuery('#notify_users').html(watcher.substring(0,watcher.length-2));
        }
}

function autocomplete(input_field, path, after_callback) {
               jQuery(input_field).autocomplete({source: path, select: after_callback, delay: 800, minLength: 3});
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


function init_task_form() {
    jQuery('#task_status').change(function() {
      if( jQuery('#task_status').val() == "5" ) {
        jQuery('#defer_options').show();
      } else {
        jQuery('#defer_options').hide();
      }
      return false;
    });
    jQuery('#comment').focus();

    attach_behaviour_to_project_select();
    jQuery("div.log_history").tabs();
    jQuery('.autogrow').autogrow();
    jQuery('#comment').keyup(function() {
        highlightWatchers();
    });
    jQuery('a.lightbox').nyroModal();

    jQuery('#task_attachments a.close-cross').click(function(){
        if(!confirm(jQuery(this).attr('data-message'))) { return false; }
        var div=jQuery(this).parent();
        div.fadeOut();
        div.html('<input type="hidden" name="delete_files[]" value="' + div.attr('id').split('-')[1] + '">');
        return false;
    });
    jQuery(function() {
        jQuery('#search_filter').catcomplete({
              source: '/task_filters/search',
              select: addSearchFilter,
              delay: 800,
              minLength: 3
        })
    });
    autocomplete('#task_customer_name_auto_complete', '/tasks/auto_complete_for_customer_name', addCustomerToTask);
    autocomplete('#dependencies_input', '/tasks/auto_complete_for_dependency_targets', addDependencyToTask);
    autocomplete('#resource_name_auto_complete', '/tasks/auto_complete_for_resource_name/customer_id='+ jQuery('#resource_name_auto_complete').attr('data-customer-id'), addResourceToTask);
    autocomplete('#user_name_auto_complete', '/tasks/auto_complete_for_user_name', addUserToTask);
    autocomplete_multiple_remote('#task_set_tags', '/tags/auto_complete_for_tags' );

    jQuery('.task-todo').sortable({update: function(event,ui){
        var todos= new Array();
        jQuery.each(jQuery('.task-todo li'),
                  function(index, element){
                      var position = jQuery('input#todo_position', element);
                      position.val(index+1);
                      todos[index]= {id: jQuery('input#id', element).val(), position: index+1} ;
                  });
        jQuery.ajax({ url: '/todos/reorder', data: {task_id: jQuery('input#task_id').val(), todos: todos }, type: 'POST' });
      }
    });

    jQuery('#snippet').click(function() {
      jQuery(this).children('ul').slideToggle();
    });

    jQuery('#snippet ul li').hover(function() {
      jQuery(this).toggleClass('ui-state-hover');
    });

    jQuery('#snippet ul li').click(function() {
      var id = jQuery(this).attr('id');
      id = id.split('-')[1];
      jQuery.ajax({ url: '/pages/snippet/'+id, type:'GET', success: function(data) {
        jQuery('#comment').val(jQuery('#comment').val() + '\n' + data);
      } });
    });

}

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

function hide_unneeded_inputs_for_task_template() {
    jQuery("#task_dependencies").hide();
    jQuery("#snippet").hide();
    jQuery("#upload_container").hide();
    jQuery("#task_information > textarea.autogrow").hide();
    jQuery("#accessLevel_container").hide();
    jQuery("#worktime_container").hide();
    jQuery("#task_time_links").hide();
    jQuery("#notify_users").hide();
    jQuery("#task_information > br").hide();
}
