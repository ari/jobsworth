
var jobsworth = jobsworth || {}
jobsworth.tasks = jobsworth.tasks || {}

jobsworth.tasks.NextTaskPanel = (function($) {
  function NextTaskPanel(options) {
    this.options = options;
    this.options["popover_placement"] = options["popover_placement"] || "left"
    this.el = options.el;
    this.initialize();
    this.bindEvents();
  }

  NextTaskPanel.prototype.initialize = function() {
    var container = $(this.el);

    $('li a[data-content]', container).popover({
      placement: this.options["popover_placement"],
      trigger: "hover",
      html: true
    })

    $("ul", container).sortable({
      stop: function(event, ui) {
        var moved = ui.item.find("a[data-taskid]").data("taskid");
        var prev = ui.item.prev("li").find("a[data-taskid]").data("taskid");
        $.post("/tasks/change_task_weight", {"prev": prev, "moved": moved});
      }
    });

  }

  NextTaskPanel.prototype.bindEvents = function() {
    var self = this;
    var container = $(this.el);

    $("a.more_tasks", container).live('click', function(){
      var count = $('ul li', container).length + 5;
      $.get("/tasks/nextTasks?count=" + count, function(data) {
        $("ul", container).html($(data.html).find("ul li"));

        $('li a[data-content]', container).popover({
           placement: self.options["popover_placement"],
           trigger: "hover",
           html: true
        })

        // if no more available
        if (!data.has_more) $("a.more_tasks", container).remove();
      })
      return false;
    });

    $(".collapsable-button").live("click", function() {
      var panel = $(this).parents(".next_tasks_panel");
      panel.toggleClass("collapsed");
    })

  }

  return NextTaskPanel;
})($)
