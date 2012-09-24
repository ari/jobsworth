var jobsworth = jobsworth || {}

jobsworth.Gantt = (function($){

  function Gantt(options) {
    this.options = options;
    this.init();
    this.bind();
  }

  Gantt.prototype.bind = function() {
    var self = this;
  }

  Gantt.prototype.init = function() {
    var self = this;
    this.options.container.gantt({
      source: "/tasks/gantt?format=json",
      scale: "days",
      minScale: "days",
      maxScale: "months",
      itemsPerPage: 20,
      navigate: "scroll",
      onItemClick: function(data) {
      },
      onAddClick: function(dt, rowId) {
      },
      onRender: function() {
        $(".bar", self.options.container).each(function() {
          var dataObj = $(this).data("dataObj");
          $(this).popover({
            placement: "right",
            title: dataObj.title,
            content: dataObj.content
          })
        })
      }
    });
  }

  return Gantt;
})(jQuery);
