// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

var jobsworth = jobsworth || {};
jobsworth.tasks = jobsworth.tasks || {};

jobsworth.tasks.TaskEditor = (function ($) {
  function TaskEditor(options) {
    this.options = options;
    this.taskId = this.options.taskId;
    this.el = this.options.el;
    this.initialize();
    this.bindEvents();
  }

  TaskEditor.prototype.initialize = function () {
    var detailContainer = $("#task_details", $(this.el))[0];
    this.taskDetailsEditor = new jobsworth.tasks.TaskDetailsEditor({taskId: this.taskId, el: detailContainer});

    var notificationContainer = $("#task_notify", $(this.el))[0];
    this.taskNotificationEditor = new jobsworth.tasks.TaskNotificationEditor({
      taskId: this.taskId,
      el: notificationContainer
    });

    
    
    $('#task_hide_until').datepicker({dateFormat: userDateFormat});

    $('#comment').focus();
    $('.autogrow').autoGrow();

    $('#dependencies_input').autocomplete({
      source: '/tasks/auto_complete_for_dependency_targets',
      select: function (event, ui) {
        var id = ui.item.id;
        $(this).val("");
        $.get("/tasks/dependency/", {dependency_id: id}, function (data) {
          $("#task_dependencies .dependencies").append(data);
        }, 'html');
        return false;
      },
      delay: 800,
      minlength: 3
    });

    $('.resource_no .remove_link').click(function () {
      $(this).parent(".resource_no").remove();
    });
    $('#resource_name_auto_complete').autocomplete({
      source: '/tasks/auto_complete_for_resource_name?customer_ids=' + this.taskNotificationEditor.getCustomerIds().join(','),
      select: function (event, ui) {
        var id = ui.item.id;
        $(this).val("");
        $.get("/tasks/resource/", {resource_id: id}, function (data) {
          $("#task_resources").append(data);
        }, 'html');
        return false;
      },
      delay: 800,
      minlength: 3
    });

    autocomplete_multiple_remote('#task_set_tags', '/tags/auto_complete_for_tags');

    $('#task_service_tip').popover({
      trigger: "hover",
      html: true,
      content: function () {
        return $("#task_service_id option:selected").attr("title");
      }
    });
    $('#task_service_tip').hover(function () {
      $(this).siblings(".popover").addClass('service-tip-popover-style');
    });

    this.updateBillable();
    this.snooze_effects();

    if (/task_templates/.test(document.location.pathname)) {
      $("#task_dependencies").hide();
      $("#snippet").hide();
      $("#upload_container").hide();
      $("#task_information textarea.autogrow").hide();
      $("#accessLevel_container").hide();
      $("#task_time_links").hide();
      $("#notify_users").hide();
      $("img#add_attachment").hide();
    }
  };

  TaskEditor.prototype.bindEvents = function () {
    var self = this;

    $(this.taskDetailsEditor.el).on('project:changed', function (e, projectId) {
      if (projectId == "") return;

      self.taskNotificationEditor.projectChangedHandler(projectId);
      self.updateBillable();
    });

    $(this.taskNotificationEditor.el).on('customers:changed', function (e, customerIds) {
      // update autocomplete query string
      $('#resource_name_auto_complete').autocomplete(
          'option',
          'source',
          '/tasks/auto_complete_for_resource_name?customer_ids=' + customerIds.join(',')
      );

      // update service options
      $.getJSON("/tasks/refresh_service_options", {
        taskId: this.taskId,
        customerIds: customerIds.join(',')
      }, function (data) {
        $("#task_service_id", $(self.el)).html(data.html);
      });

      self.updateBillable();
    });

    $('#comment').keyup(function () {
      self.highlightWatchers();
    });

    $('#snippet-dropdown ul li').click(function () {
      var id = $(this).attr('id');
      if (!id) return true;

      id = id.split('-')[1];
      $.get('/snippets/' + id + '.json', function (data) {
        $('#comment').val($('#comment').val() + '\n' + data.body);
      });

      $('#snippet-dropdown').toggleClass("open");

      return false;
    });

    $('#user_access_public_privat').click(function () {
      self.toggleAccess();
      return false;
    });

    $("#snooze_until_datepicker").click(function () {
      $('#task_hide_until').datepicker('show');
      return false;
    });

    $('#task_hide_until').change(function () {
      $('#snooze_until_date span').html($(this).val());
      if ($(this).val().length > 0) {
        $('#snooze_until_date').show();
      }
    });

    $('#snooze_until_datepicker').click(function () {
      $('#task_hide_until').datepicker('show');
      return false;
    });

    $('#remove_snooze_until_date').click(function () {
      $('#snooze_until_date').hide();
      $('#task_hide_until').val('');
      return false;
    });

    // remove customer response link
    $('#customer_response .removeLink').click(function () {
      $(this).parents("#customer_response").remove();
      $('#task_wait_for_customer').attr('checked', false);
      $('#snooze_until').hide();
      return false;
    });

    $(".task_attachment a.removeLink").click(function () {
      var file_node = $(this).parents('.task_attachment');
      var file_id = file_node.data('id');
      var file_name = file_node.data('name');
      self.remove_file_attachment(file_id, "Do you really want to delete " + file_name);
      return false;
    });

    $("#task_service_id").change(function () {
      self.updateBillable();

      var service_id = $("#task_service_id").val();
      if (service_id == "0" || service_id == "-1") {
        $('#task_service_tip').hide();
      } else {
        $('#task_service_tip').show();
      }
    });
    $("#task_service_id").change();
  };

  TaskEditor.prototype.updateBillable = function () {
    
    var projectId = this.taskDetailsEditor.getProjectId();
    var customerIds = this.taskNotificationEditor.getCustomerIds().join(",");
    var serviceId = $("#task_service_id").val();

    if (!projectId || customerIds.length == 0) return;

    $.get("/tasks/billable", {
      project_id: projectId,
      customer_ids: customerIds,
      service_id: serviceId
    }, function (data) {
      if (data.billable) {
        $("#billable-label").text("billable");
      } else {
        $("#billable-label").text("unbillable");
      }
    })
  };

  TaskEditor.prototype.highlightWatchers = function () {
    var comment_val = $('#comment').val();

    if (comment_val == '') {
      $('.watcher').removeClass('will_notify');
      $('#notify_users').html('');
    } else {
      if ($('#accessLevel_container div').hasClass('private')) {
        $('.watcher').removeClass('will_notify');
        $('.watcher.access_level_2').addClass('will_notify');
      } else {
        $('.watcher').addClass('will_notify');
      }

      var watcher = "Notify: ";
      $('div.watcher.will_notify a.username span').each(function () {
        watcher = watcher + $(this).html() + ", ";
      });
      $('#notify_users').html(watcher.substring(0, watcher.length - 2));
    }
  };


  TaskEditor.prototype.toggleAccess = function () {
    if ($('#accessLevel_container div').hasClass('private')) {
      $('#accessLevel_container div').removeClass('private');
      $('#work_log_access_level_id').val('1');
      $('#work_log_access_level_id option').removeAttr('selected');
      $('#work_log_access_level_id option:nth-child(1)').prop('selected', true);
      $('#snooze_until').show();
    } else {
      $('#accessLevel_container div').addClass('private');
      $('#work_log_access_level_id').val('2');
      $('#work_log_access_level_id option').removeAttr('selected');
      $('#work_log_access_level_id option:nth-child(2)').prop('selected', true);
      if ($('#task_wait_for_customer').attr('checked')) {
        $('#snooze_until').hide();
      }
    }
    this.highlightWatchers();
  };

  TaskEditor.prototype.remove_file_attachment = function (file_id, message) {
    var answer = confirm(message);
    if (!answer) return;

    $.ajax({
      url: '/project_files/' + file_id + '/destroy_file',
      type: 'DELETE',
      dataType: 'json',
      success: function (response) {
        if (response.status == 'success') {
          var div = $('#projectfiles-' + file_id);
          div.fadeOut('slow');
          div.html('<input type="hidden" name="delete_files[]" value="' + file_id + '">');
        } else {
          flash_message(response.message);
        }
      },
      error: function (xhr, thrownError) {
        alert("Error : " + thrownError);
      }
    });
  };

  TaskEditor.prototype.snooze_effects = function () {
    function formatDate(d) {
      return d.getDate() + "/" + (d.getMonth() + 1) + "/" + d.getFullYear();
    }

    if ($('#snooze_until_date span').text().length > 0 || $('#task_wait_for_customer').prop('checked') || $('.dependencies').text().length > 8) {
      $('#snooze-btn #snooze-btn-val').text('Snoozed');
      $('#target-date label').text('Snoozed until');
      $('#due_at').hide();
    }
    $('#snooze-btn').on('click', function () {
      $('#snooze-btn #snooze-btn-val').text('Snooze');
      $('#target-date label').text('Target');
      $('#snooze_until_date, #customer-reply-label, #show-till-other-task').hide();
      $('#task_hide_until').val('');
      $('#task_wait_for_customer').prop('checked', false);
      $('#due_at').show();
      $('#snooze_until_date span').text('');
    });

    $('#snooze-dropdown .dropdown-menu li').on('click', function () {
      var tomorrow = new Date();
      tomorrow.setDate(tomorrow.getDate() + 1);

      var next_mon = new Date();
      next_mon.setDate(next_mon.getDate() + (1 + 7 - next_mon.getDay()) % 7);

      $('#snooze-btn #snooze-btn-val').text('Snoozed');
      $('#target-date label').text('Snoozed until');
      $('#due_at').hide();

      switch (this.id) {
        case 'snooze-till-tomorrow':
          $('#snooze_until_date span').html(formatDate(tomorrow));
          $('#task_hide_until').val(formatDate(tomorrow));
          $('#snooze_until_date').show();
          $('#show-till-other-task, #customer-reply-label').hide();
          break;
        case 'snooze-till-next-week':
          $('#snooze_until_date span').html(formatDate(next_mon));
          $('#task_hide_until').val(formatDate(next_mon));
          $('#snooze_until_date').show();
          $('#show-till-other-task, #customer-reply-label').hide();
          break;
        case 'snooze-till-customer-reply':
          $('#task_wait_for_customer').prop('checked', true);
          $('#show-till-other-task').hide();
          $('#customer-reply-label').show();
          break;
        case 'snooze-till-other-task':
          $('#show-till-other-task').show();
          $('#customer-reply-label').hide();
          break;
        case 'snooze-till-date':
          $('#snooze_until_date').show();
          $('#snooze_until_date span').html('choose the date');
          $('#task_hide_until').datepicker('show');
          $('#show-till-other-task, #customer-reply-label').hide();

          break;
      }
    });

    if ($('#task_wait_for_customer').prop('checked')) {
      $('#customer-reply-label').show();
    } else {
      $('#customer-reply-label').hide();
    }
    if ($('.dependencies').text().length > 8) {
      $('#show-till-other-task').show();
      $('#customer-reply-label').hide();
    }
  };

  return TaskEditor;
})(jQuery);
