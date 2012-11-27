var jobsworth = jobsworth || {}

jobsworth.UserPermissions = (function($){
  function UserPermissions(userId) {
    this.userId = userId;

    var self = this;
    autocomplete('#user_project_name_autocomplete', '/users/auto_complete_for_project_name', function(event, ui) {
      self.addProjectToUser(event, ui);
    });

  }

  UserPermissions.prototype.addProjectToUser = function(event, ui) {
    var value = ui.item.id;
    var url = "/users/project/" + this.userId;

    $.get(url, { project_id: value }, function(data) {
      $("#add_user").before(data);
    }, 'html');

    jQuery(this).val("");
    return false;
  }

  return UserPermissions;
})(jQuery)