// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

var jobsworth = jobsworth || {};
jobsworth.tasks = jobsworth.tasks || {};

jobsworth.tasks.TaskDetailsEditor = (function ($) {
  function TaskDetailsEditor(options) {
    this.options = options;
    this.taskId = this.options.taskId;
    this.el = this.options.el;
    this.initialize();
    this.bindEvents();
  }

  TaskDetailsEditor.prototype.initialize = function () {
    var self = this;

    $('#due_date_field').find('input').datepicker({
      constrainInput: false,
      dateFormat: userDateFormat
    });
    self.projectId = $('#task_project_id').val();
    self.checkMilestones(self.projectId);
  };

  TaskDetailsEditor.prototype.bindEvents = function () {
    var self = this;

    // add project change listener
    $('#task_project_id').change(function () {
      self.projectId = $('#task_project_id').val();
      self.refreshMilestones(self.projectId, 0);
      self.addDefaultUsers(self.projectId);
      $(self.el).trigger("project:changed", self.projectId);
    });

    // add milestone click
    $('#add_milestone').click(function () {
      self.addMilestone();
      return false;
    });

    // milestone change
    $('#task_milestone_id').change(function () {
      if ($('#due_date_field input').val().length == 0) {
        $('#due_date_field input').attr("placeholder", $('#task_milestone_id :selected').attr('data-date'));
      }

      $('#task_milestone_id').attr("data-original-title", $('#task_milestone_id :selected').attr('title'));
    });
  };

  TaskDetailsEditor.prototype.getProjectId = function () {
    return $('#task_project_id').val();
  };

  TaskDetailsEditor.prototype.addDefaultUsers = function (pid) {
    var self = this;
    var projectId = pid;
    $('#task_users .user_list .new-default-watcher').remove();
    var users = $('.username span').map(function () {
      return $(this).text();
    }).get();
    var params = {project_id: projectId, id: this.options.taskId, users: users};
    $.get({
      url: '/tasks/get_default_watchers_for_project',
      data: params,
      cache: false,
      success: function (data) {
        var new_data = $('<div>' + data + '</div>');
        new_data.find('.watcher').addClass('new-default-watcher');
        var marked_data = new_data.html();
        jQuery("#task_users  div.user_list").append(marked_data);
        $(self.el).trigger("users:changed");
      },
      dataType: 'html'
    });
    return false;
  };

  TaskDetailsEditor.prototype.addMilestone = function () {
    var self = this;
    if ($("#task_project_id").val() == "") {
      alert("Please select project before adding milestone !!");
      return;
    }

    $("#ui_popup_dialog").remove();
    $.get("/milestones/new?project_id=" + $("#task_project_id").val(), function (data) {
      $('body').prepend(data);
      $('#ui_popup_dialog').modal('show');

      $('#add_milestone_form').submit(function () {
        $('#errorExplanation').remove();
        if ($("#milestone_name").val() == 0) {
          $('<div>').attr({'id': 'errorExplanation', 'class': 'errorExplanation'})
              .append('Name can not be blank').insertBefore('#add_milestone_form');
          return false;
        }
      });

      // refresh milestone and destroy dialog after a successful milestone addition
      $('#add_milestone_form').bind("ajax:success", function (event, json, xhr) {
        $('#ui_popup_dialog').modal('hide');
        authorize_ajax_form_callback(json);
        var project_id = json.project_id;
        var milestone_id = json.milestone_id;
        self.refreshMilestones(project_id, milestone_id);
      });
    });
  };
  // check the milestones presence for project
  TaskDetailsEditor.prototype.checkMilestones = function (pid) {
    $.getJSON("/milestones/get_milestones", {project_id: pid},
        function (data) {
          console.log('check milestones');
          if (data.options.length > 1) {
            $('#milestone-selector').show();
          } else {
            $('#milestone-selector').hide();
          }
        });
  };
  // refresh the milestones select menu for all milestones from project pid, setting the selected milestone to mid
  TaskDetailsEditor.prototype.refreshMilestones = function (pid, mid) {
    var self = this;
    var select = $('#task_milestone_id');

    if (pid == '') {
      select.empty();
      select.append($("<option data-date=\"Not set\" value= \"0\" >[none]</option>"));
      return;
    }

    $.getJSON("/milestones/get_milestones", {project_id: pid},
        function (data) {
          select.empty();
          var options = data.options;
          for (var i = 0; i < options.length; i++) {
            select.append($("<option data-date=\"" + options[i].date + "\" title=\"" + options[i].title + "\" value=\"" + options[i].value + "\" >" + options[i].text + "</option>"));
          }

          $("#task_milestone_id option[value='" + mid + "']").attr('selected', 'selected');
          if (data.add_milestone_visible) {
            $('#add_milestone').show();
          } else {
            $('#add_milestone').hide();
          }
          if (options.length > 1) {
            $('#milestone-selector').show();
          } else {
            $('#milestone-selector').hide();
          }
        });
  };

  return TaskDetailsEditor;
})(jQuery);
