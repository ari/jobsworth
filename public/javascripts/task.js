// -------------------------
//  Task edit
// -------------------------

/* Load a task into the edit panel by ajax */
function loadTask(id) {
	jQuery("#task").fadeOut();
	jQuery.get("/tasks/edit/" + id, {}, function(data) {
		jQuery("#task").html(data);
		jQuery("#task").fadeIn('slow');
		init_task_form();
  });
}

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


// refresh the milestones select menu for all milestones from project pid, setting the selected milestone to mid
// also old /milestones/get_milestones returns line of javasript code `jQuery('#add_milestone').[show()|hide]`
// new /milestones/get_milestones returns flag add_milestone_visible
function refreshMilestones(pid, mid) {
  jQuery.getJSON("/milestones/get_milestones", {project_id: pid},
    function(data) {
      var milestoneSelect = jQuery('#task_milestone_id').get(0);
      rebuildSelect(milestoneSelect, data.options);
      milestoneSelect.options[mid].selected = true;
      if (data.add_milestone_visible){
        jQuery('#add_milestone').show();
      } else{
        jQuery('#add_milestone').hide();
      }
  });
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

/*
 Add function to handle open/close task
 For New Task
*/

function new_todo_open_close_check(val, sender, time, formatted_time, user, user_id) {
    if (val == true) {
        jQuery(sender).attr("title", "Close <b>" + jQuery(sender).val() + "</b>");
        jQuery(sender).siblings(".completed_by_user_id").val(user_id);
        jQuery(sender).siblings(".completed_at").val(time);
        jQuery(sender).siblings(".new_todo_complete").val(true);
        jQuery(sender).parent().attr("class", "todo todo-completed");
        jQuery(sender).siblings(".todo_not_yet_done").hide();
        jQuery(sender).siblings(".todo_done").show();
        jQuery(sender).siblings(".edit").hide();
        jQuery(sender).siblings(".todo_done").children(".time").text("["+formatted_time+"]");
        jQuery(sender).siblings(".todo_done").children(".user").text("["+user+"]");
    } else {
        jQuery(sender).attr("title", "Open <b>" + jQuery(sender).val() + "</b>");
        jQuery(sender).siblings(".completed_by_user_id").val(" ");
        jQuery(sender).siblings(".completed_at").val(" ");
        jQuery(sender).siblings(".new_todo_complete").val(false);
        jQuery(sender).parent().attr("class", "todo todo-active");
        jQuery(sender).siblings(".todo_not_yet_done").show();
        jQuery(sender).siblings(".todo_done").hide();
    }
}

/*
  Add function to handle new todo
  For new Task
*/


function new_task_form() {
    var todo = jQuery("#todos-clone").children("li:last-child");
    var display = todo.find(".display");
    var edit = todo.find(".edit");

    display.toggle();
    edit.toggle();
}

function addNewTodoKeyListenerForUncreatedTask(sender, button) {
     if (button == "edit") {
       var li_element = jQuery(sender).parent().parent();
       var input = jQuery(sender).parent().siblings(".edit").children("input");
     } else if (button == "new") {
       var li_element = jQuery("#todos-clone").children("li:last-child");
       var input = li_element.children("span.edit").children("input");
     }

    input.keypress(function(key) {
        if (key.keyCode == 13) {
            li_element.children(".display").show();
            li_element.children(".display").text(input.val());
            li_element.children(".edit").children("input").val(input.val());
            li_element.children(".edit").hide();

            key.stopPropagation();
            return false;
        }
    });
}

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
        });
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

    jQuery('#add_milestone img').click(add_milestone_popup);
    jQuery('#task_project_id').change(function() {
      jQuery("#milestone_project_id").val(jQuery('#task_project_id').val());
    });
}

// this variable is used to cache the last state so we don't run
// all of highlightWatchers() on every keystroke
var task_comment_empty = null;

function highlightWatchers() {
	var comment_val = jQuery('#comment').val();
	
  if (comment_val !== task_comment_empty) {
	  if (comment_val == '') {
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
	  task_comment_empty = (comment_val == '');
  }
}

function add_milestone_popup() {
  if (jQuery("#task_project_id").val() == "") {
    alert("Please select project before adding milestone !!")
  } else {
    jQuery("#milestone_name").val(" ");
    jQuery("#milestone_due_at").val(" ");
    jQuery("#milestone_user_id").val(" ");
    jQuery("#milestone_description").val(" ");
    var popup = jQuery("span#ui_popup_dialog").dialog({
        autoOpen: false,
	    title: 'New Milestone',
        width: 370,
        draggable: true
	});
	popup.dialog('open');
	return false;
  }
}