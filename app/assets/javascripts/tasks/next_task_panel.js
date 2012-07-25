
var jobsworth = jobsworth || {}
jobsworth.tasks = jobsworth.tasks || {}

jobsworth.tasks.NextTaskPanel = (function($) {
  function NextTaskPanel(options) {
    this.el = options.el;
    this.initialize();
    this.bindEvents();
  }

  NextTaskPanel.prototype.initialize = function() {
    var container = $(this.el);

    $('li a[data-content]', container).popover({
      placement: "left"
    })

    $("ul", container).sortable({
      stop: function(event, ui) {
        var moved = ui.item.children("a").data("taskid");
        var prev = ui.item.prev("li").children("a").data("taskid");
        $.post("/tasks/change_task_weight", {"prev": prev, "moved": moved});
      }
    });

  }

  NextTaskPanel.prototype.bindEvents = function() {
    var self = this;
    var container = $(this.el);

    $("a.more_tasks", container).click(function(){
      var count = $('ul li', container).length + 5;
      $.get("/tasks/nextTasks?count=" + count, function(data) {
        $("ul", container).html($(data.html).find("ul li"));

        $('li a[data-content]', container).popover({
           placement: "left"
        })

        // if no more available
        if (!data.has_more) $("a.more_tasks", container).remove();
      })
      return false;
    });
  }

  return NextTaskPanel;
})($)
