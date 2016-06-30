var jobsworth = jobsworth || {};
jobsworth.tasks = jobsworth.tasks || {};

jobsworth.tasks.Planning = (function ($) {

  function Planning() {
    this.init();
    this.bind();
  }

  Planning.prototype.bind = function () {
    var self = this;

    $(".next_tasks_panel a.more_tasks").live("click", function () {
      var parent = $(this).parents(".next_tasks_panel");
      var user_id = parent.data("user");
      var count = $('ul li', parent).length + 5;

      $.get("/tasks/nextTasks?count=" + count + "&user_id=" + user_id, function (data) {
        $("ul", parent).html($(data.html).find("ul li"));

        $('li a[data-content]', parent).popover({
          trigger: "hover",
          html: true,
          placement: "right"
        });

        // if no more available
        if (!data.has_more) $("a.more_tasks", parent).remove();

        self.relayout();
      });

      return false;
    });

    $("#collapse-all").click(function () {
      $(".next_tasks_panel").addClass("collapsed");
      self.relayout();
    });

    $("#show-all").click(function () {
      $(".next_tasks_panel").removeClass("collapsed");
      self.relayout();
    });

    $(".next_tasks_panel .collapsable-button").live("click", function () {
      var panel = $(this).parents(".next_tasks_panel");
      panel.toggleClass("collapsed");
      self.relayout();
    })
  };

  Planning.prototype.relayout = function () {
    $('#next-tasks-container').masonry('reload')
  };

  Planning.prototype.init = function () {
    $('#next-tasks-container').masonry({
      itemSelector: '.next_tasks_panel'
    });

    $(".next_tasks_panel ul").sortable({
      stop: function (event, ui) {
        var parent = $(ui.item).parents(".next_tasks_panel");
        var user_id = parent.data("user");
        var moved = $("a[data-taskid]", ui.item).data("taskid");
        var prev = $("a[data-taskid]", ui.item.prev("li")).data("taskid");
        $.post("/tasks/change_task_weight", {"prev": prev, "moved": moved, "user_id": user_id});
      }
    });

    $('.next_tasks_panel li a[data-content]').popover({
      placement: "right",
      html: true,
      trigger: "hover"
    })
  };

  return Planning;
})(jQuery);
