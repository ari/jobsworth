var jobsworth = jobsworth || {}

jobsworth.ProjectPermissions = (function($){
  function ProjectPermissions(projectId) {
    this.projectId = projectId;

    var self = this;
    autocomplete('#project_user_name_autocomplete', '/users/auto_complete_for_user_name', function(event, ui) {
      self.addUserToProject(event, ui);
    });

  }

  ProjectPermissions.prototype.addUserToProject = function(event, ui) {
    var value = ui.item.id;
    var url = "/projects/ajax_add_permission/" + this.projectId;

    $.get(url, { user_id : value }, function(data) {
        $("#user_table").html(data);
    }, 'html');
    return false;
  }

  return ProjectPermissions;

})(jQuery)