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
      source: "/tasks/gantt.json",
      scale: "weeks",
      minScale: "weeks",
      maxScale: "months",
      itemsPerPage: 50,
      navigate: "scroll",
      onItemClick: function(data) {
      },
      onAddClick: function(dt, rowId) {
      }
    });
  }

  return Gantt;
})(jQuery);
