var jobsworth = jobsworth || {};

jobsworth.UserPermissions = (function ($) {
  function UserPermissions(userId) {
    this.userId = userId;

    var self = this;
    autocomplete('#user_project_name_autocomplete', '/users/auto_complete_for_project_name?user_id=' + userId, function (event, ui) {
      self.addProjectToUser(event, ui);
      $(this).val("");

      return false;
    });
  }

  UserPermissions.prototype.addProjectToUser = function (event, ui) {
    var value = ui.item.id;
    var status_completed = ui.item.status_completed
    var url = "/users/" + this.userId + "/project/";

    if (status_completed == true) {
      $("#completed_project").slideDown(function() {
        setTimeout(function() {
          $("#completed_project").slideUp();
        }, 5000);
      });
      return;
    } else {
      $.get(url, {project_id: value}, function (data) {
        $("#add_user").before(data);
      }, 'html');
    }
  };
  return UserPermissions;
})(jQuery);