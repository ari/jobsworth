jobsworth.Task = (function($){
  function Task(id) {
    this.load(id);
  }

  Task.prototype.load = function(id) {
    if (window.taskTimer) window.taskTimer.destroy();

    var self = this;
    $.getJSON("/tasks/edit/" + id, function(data) {
      $("#task").fadeOut();
      $("#task").html(data.html);
      $("#task").fadeIn();
      document.title = "Task " + data.task_num + ":" + data.task_name;
      $("#task [rel=tooltip]").tooltip();

      self.init();
    });
  }

  Task.prototype.init = function() {
    $('#taskform').bind("ajax:success", function(event, json, xhr) {
      authorize_ajax_form_callback(json);
      var task = json;
      $('#errorExplanation').remove();
      $("span.fieldWithErrors").removeClass("fieldWithErrors");
      if (task.status == "error") {
        var html = "<div class='errorExplanation' id='errorExplanation'>";
        html += "<h2>"+ task.messages.length +" error prohibited this template from being saved</h2><p>There were problems with the following fields:</p>";
        for (i=0 ; i < task.messages.length ; i++) {html += "<ul><li>"+ task.messages[i] + "</li></ul>";}
        html += "</div>"
        $(html).insertAfter("#task_id");
      }
      else {
        if (window.grid) window.grid.reload();
        //update tags
        $("#tags").replaceWith(html_decode(task.tags));
        new jobsworth.Task(task.tasknum);
        flash_message(task.message);
      }
    }).bind("ajax:failure", function(event, json, xhr, error) {
      alert('error: ' + error);
    });
  }

  return Task;
})(jQuery)