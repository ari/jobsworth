/*
  Disable all the features of tasks which
  aren't needed in templates
*/
jQuery(document).ready(function() {

  if ( /task_templates\//.test(document.location.pathname)) {
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

  /*
    Create new tasks from a template when you
    click on the menu item
  */
  jQuery('li.task_template a').click(create_task_from_template);
  
});

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
    });
}
