// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

var jobsworth = jobsworth || {}
jobsworth.tasks = jobsworth.tasks || {}

jobsworth.tasks.TaskNotificationEditor = (function($) {
  function TaskNotificationEditor(options) {
    this.options = options;
    this.el = this.options.el;
    this.initialize();
    this.bindEvents();
  }

  TaskNotificationEditor.prototype.initialize = function() {
    var self = this;
    autocomplete('#task_customer_name_auto_complete', '/customers/auto_complete_for_customer_name', function(event, ui) {
      self.customerAddHandler(event, ui);
      return false;
    });

    autocomplete('#user_name_auto_complete', '/users/auto_complete_for_user_name', function(event, ui) {
      self.userAddHandler(event, ui);
      return false;
    });

  }

  TaskNotificationEditor.prototype.bindEvents = function() {
    var self = this;

    // add me click
    $('#add_me').click(function(){
      $('#task_users > div:first').append($(this).data('notification'));

      if(!$('input[name=\"assigned[]\"]:enabled').size()) {
        $('#task_notify div.watcher:last > label > a').trigger('click');
      };

      return false;
    });

    // users to add popup
    $('#users_to_notify_popup_button').click(function() {
      if($('#users_to_notify_list').is(':visible')) {
        return $('#users_to_notify_list').hide();
      }

      self.showUsersToNotifyPopup();
    });

    // toggle assigned
    $(this.el).on('click', ".watcher .toggle-link", function() {
      self.toggleTaskIcon(this);
      return false;
    })

    // delete watcher
    $(this.el).on('click', ".watcher .removeLink", function() {
      $(this).parents(".watcher").remove();
      return false;
    })

    // delete customer
    $(this.el).on('click', ".customer .removeLink", function() {
      $(this).parent(".customer").remove();

      self.customersChanged();
      return false;
    })

    var mouse_is_inside = false;
    $('#users_to_notify_list').hover(function(){
      mouse_is_inside=true;
    }, function(){
      mouse_is_inside=false;
    });
    $("body").mouseup(function(){
      if(!mouse_is_inside) $('#users_to_notify_list').hide();
    });

  }

  TaskNotificationEditor.prototype.showUsersToNotifyPopup = function() {
    var self = this;
    var watcherIds = $(".watcher_id").map(function () {
      return $(this).val();
    }).get().join(",");

    $('#users_to_notify_list').load("/tasks/users_to_notify_popup?id=" + self.options.taskId + "&watcher_ids=" + watcherIds, function() {
        $('#users_to_notify_list').show();

        $('#users_to_notify_list ul li a').bind('click', function() {
          $('#users_to_notify_list').hide();

          var userId = $(this).attr("id").split("_")[1];
          var params = { user_id : userId, id : self.options.taskId };
          self.addUser('/tasks/get_watcher', params);

          return false;
        });
      });

    return false;
  }

  TaskNotificationEditor.prototype.addUser = function(url, params) {
    var self = this;
    $.get(url, params, function(data) {
      $("#task_users > div:first").append(data);
      $(self.el).trigger("users:changed");
    }, 'html');
  }

  TaskNotificationEditor.prototype.userAddHandler = function(event, ui) {
    var userId = ui.item.id;
    var params = { user_id : userId, id : this.options.taskId };
    this.addUser('/tasks/get_watcher', params);

    $("#user_name_auto_complete").val("");
    return false;
  }

  TaskNotificationEditor.prototype.customerAddHandler = function(event, ui) {
    var self = this;
    var customerId = ui.item.id;
    var params = { customer_id : customerId, id : this.options.taskId };
    $.get('/tasks/get_customer', params, function(data) {
      $("#task_customers > div:first").append(data);
      self.customersChanged();
    }, 'html');

    this.addUser('/tasks/get_default_watchers_for_customer', params);

    $("#task_customer_name_auto_complete").val("");
    return false;
  }

  TaskNotificationEditor.prototype.projectChangedHandler = function(projectId) {
    var self = this;
    var customer_ids = self.getCustomerIds();

    if (customer_ids.length > 0) return;

    $.get('/tasks/get_default_customers', {project_id: projectId, id: self.options.taskId}, function(data) {
      $("#task_customers > div:first").html(data);

      // update whole list in case of project change
      $.get('/tasks/get_default_watchers', {id: self.options.taskId, project_id: projectId, customer_ids: customer_ids}, function(data) {
        $("#task_users > div:first").html(data);
      })

      self.customersChanged();
    }, 'html');
  }

  TaskNotificationEditor.prototype.toggleTaskIcon = function(sender) {
    var div = $(sender).parents(".watcher");
    var input = div.find("input.assigned");

    if (div.hasClass("is_assigned")) {
      input.attr("disabled", true);
      div.removeClass("is_assigned");
    } else {
      input.attr("disabled", false);
      div.addClass("is_assigned");
    }
  }

  TaskNotificationEditor.prototype.customersChanged = function() {
    $(this.el).trigger("customers:changed", [this.getCustomerIds()]);
  }

  TaskNotificationEditor.prototype.getCustomerIds = function() {
    var customerIds = $(".customer", $(this.el)).map(function () {
      return $(this).data("id");
    }).get();
    return customerIds;
  }

  return TaskNotificationEditor;
})(jQuery)
