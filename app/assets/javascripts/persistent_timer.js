var jobsworth = jobsworth || {};

jobsworth.PersistentTimer = (function() {
  var $ = jQuery;

  function PersistentTimer(options) {
    this.options = options;
    this.bindEvents();
  }

  PersistentTimer.prototype.bindEvents = function() {
    // Note:
    //   Function.prototype.bind is already supported by major browsers
    //   http://kangax.github.com/es5-compat-table/
    setInterval(this.refresh.bind(this), 60000);
  }

  PersistentTimer.prototype.refresh = function() {
    $.getJSON("/work/refresh", function(data) {
      $("#current-sheet-duration").text(data.duration);
      $("#current-sheet-total").text(data.total);
      $("#current-sheet-percent").text(data.percent);
    })
  }

  return PersistentTimer;
})();

