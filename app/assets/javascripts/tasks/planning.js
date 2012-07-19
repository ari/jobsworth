var jobsworth = jobsworth || {}
jobsworth.tasks = jobsworth.tasks || {}

jobsworth.tasks.Planning = (function($){

  function Planning() {
    this.init();
    this.bind();
  }

  Planning.prototype.bind = function() {
    var self = this;

    $(".next_tasks_panel a.more_tasks").live("click", function(){
      var parent = $(this).parents(".next_tasks_panel");
      var user_id = parent.data("user");
      var count = $('ul li', parent).length + 5;
      $('ul', parent).load("/tasks/nextTasks?count=" + count + "&user_id=" + user_id + " ul li", function(){ self.relayout(); });
      return false;
    });

    $(".next_tasks_panel .collapsable-button").live("click", function() {
      var panel = $(this).parents(".next_tasks_panel");
      panel.toggleClass("collapsed");
      self.relayout();
    })
  }

  Planning.prototype.relayout = function() {
    $('#next-tasks-container').isotope('reLayout');
  }

  Planning.prototype.init = function() {
    $('#next-tasks-container').isotope({
      itemSelector : '.next_tasks_panel',
      layoutMode : 'masonry'
    });

    $(".next_tasks_panel ul").sortable({
      stop: function(event, ui) {
        var parent = $(ui.item).parents(".next_tasks_panel");
        var user_id = parent.data("user");
        var moved = $("a[data-taskid]", ui.item).data("taskid")
        var prev = $("a[data-taskid]", ui.item.prev("li")).data("taskid")
        $.post("/tasks/change_task_weight", {"prev": prev, "moved": moved, "user_id":user_id});
      }
    });
  }

  return Planning;
})(jQuery);
