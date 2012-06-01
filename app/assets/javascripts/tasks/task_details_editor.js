// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

var jobsworth = jobsworth || {}
jobsworth.tasks = jobsworth.tasks || {}

jobsworth.tasks.TaskDetailsEditor = (function($) {
  function TaskDetailsEditor(options) {
    this.options = options;
    this.taskId = this.options.taskId;
    this.el = this.options.el;
    this.initialize();
    this.bindEvents();
  }

  TaskDetailsEditor.prototype.initialize = function() {
    var self = this;

    $('div#due_date_field input').datepicker({
      constrainInput: false,
      dateFormat: userDateFormat,
      onSelect: function() {
        self.setTargetDate();
      }
    });
  };

  TaskDetailsEditor.prototype.bindEvents = function() {
    var self = this;

    // add project change listener
    $('#task_project_id').change(function(){
      self.projectId = $('#task_project_id').val();
      self.refreshMilestones(self.projectId, 0);
      $(self.el).trigger("project:changed", self.projectId);
    });

    // add milestone click
    $('#add_milestone').click(function() {
      self.addMilestone();
      return false;
    });

    // due date click
    $('div#target_date a#override_target_date').click(function(){
      $('div#target_date').hide();
      $('div#due_date_field').show();
      return false;
    });

    // clear target date
    $('div#target_date a#clear_target_date').click(function(){
      $('div#target_date span').html($('#task_milestone_id :selected').attr('data-date'));
      $('div#due_date_field input').val("");
      $(this).hide();
      $('div#target_date a#override_target_date').show();
      return false;
    });

    // set target date
    $('div#due_date_field input').blur(function() {
      self.setTargetDate();
    });

    // milestone change
    $('#task_milestone_id').change(function(){
      if($('div#due_date_field input').val().length == 0){
        $('div#target_date span').html($('#task_milestone_id :selected').attr('data-date'));
      }
    });

  }

  TaskDetailsEditor.prototype.getProjectId = function() {
    return $('#task_project_id').val();
  }

  TaskDetailsEditor.prototype.addMilestone = function() {
    var self = this;
    if ($("#task_project_id").val() == "") {
      alert("Please select project before adding milestone !!");
      return;
    } 

    $("#ui_popup_dialog").remove();
    $.get("/milestones/new?project_id=" + $("#task_project_id").val(), function(data) {
      var html = "<div class=\"modal\" data-backdrop=\"false\" id=\"ui_popup_dialog\"><div class=\"modal-header\"><a class=\"close\" data-dismiss=\"modal\">×</a><h3>Create Milestone</h3></div><div class=\"modal-body\">"+ data +"</div></div>"
      $('body').prepend(html);

      $("#milestone_name").val(" ");
      $("#milestone_due_at").val(" ");
      $("#milestone_user_id").val(" ");
      $("#milestone_description").val(" ");
      $('#ui_popup_dialog').modal('show');
      $('#ui_popup_dialog').css("width", "800px").css("margin-left", "-400px");

      $('#add_milestone_form').submit(function(){
        $('#errorExplanation').remove();
        if ($("#milestone_name").val() == 0){
          $('<div>').attr({'id': 'errorExplanation', 'class': 'errorExplanation'})
          .append('Name can not be blank').insertBefore('#add_milestone_form');
          return false;
        }
      });

      // refresh milestone and destroy dialog after a successful milestone addition
      $('#add_milestone_form').bind("ajax:success", function(event, json, xhr) {
        $('#ui_popup_dialog').modal('hide')
        authorize_ajax_form_callback(json);
        var project_id = json.project_id;
        var milestone_id = json.milestone_id;
        self.refreshMilestones(project_id, milestone_id);
      });
    });
  }

  // refresh the milestones select menu for all milestones from project pid, setting the selected milestone to mid
  TaskDetailsEditor.prototype.refreshMilestones = function(pid, mid) {
    var self = this;
    var select = $('#task_milestone_id');

    if (pid == '') {
      select.empty();
      select.append($("<option data-date=\"Not set\" value= \"0\" >[none]</option>"));
      return;
    }

    $.getJSON("/milestones/get_milestones", {project_id: pid},
      function(data) {
        select.empty();
        options = data.options;

        for( var i=0; i<options.length; i++ ) {
          select.append($("<option data-date=\"" + options[i].date + "\" value= \"" + options[i].value +"\" >"+ options[i].text+ "</option>"));
        }

        $("#task_milestone_id value['"+ mid + "']").attr('selected','selected');
        if (data.add_milestone_visible){
          $('#add_milestone').show();
        } else{
          $('#add_milestone').hide();
        }
    });
  }

  TaskDetailsEditor.prototype.setTargetDate = function() {
    $('div#target_date').show();
    $('div#due_date_field').hide();
    if($('div#due_date_field input').val().length == 0){
      $('div#target_date span').html($('#task_milestone_id :selected').attr('data-date'));
    } else {
      $('div#target_date span').html($('div#due_date_field input').val());
      $('div#target_date a#override_target_date').hide();
      $('div#target_date a#clear_target_date').show();
    }
  }

  return TaskDetailsEditor;
})(jQuery)
