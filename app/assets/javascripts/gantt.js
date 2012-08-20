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
      }
    });
  }

  return Gantt;
})(jQuery);
