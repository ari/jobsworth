var jobsworth = jobsworth || {}

jobsworth.TimeLine = (function($){

  var header_template = '' +
      '<tr>' +
        '<td class="log_header" colspan="3">' +
          '<strong>' +
            '{date}' +
          '</strong>' +
        '</td>' +
      '</tr>'

  function TimeLine(options) {
    this.options = options;
    this.init();
    this.bind();
  }

  TimeLine.prototype.bind = function() {
    var self = this;

    $('#filter_date').change(function() {
      if($('#filter_date').val() == "8" ) {
        $('#date_range').show();
      } else {
        $('#date_range').hide();
      }
      return false;
    });

    $("#load-more").click(function() {
      self.loadMore();
    })
  }

  TimeLine.prototype.init = function() {
    $("#start_date").datepicker({dateFormat: this.options.dateFormat});
    $("#stop_date").datepicker({dateFormat: this.options.dateFormat});
  }

  TimeLine.prototype.loadMore = function() {
    var self = this;
    $.getJSON("/timeline/index", this.options, function(res) {
      if (res.count > 0) {
        for (var index in res.items) {
          var item = res.items[index];
          if (self.options.lastDate != item.date) {
            $("table#timeline-table").append(header_template.replace("{date}", item.date));
            self.options.lastDate = item.date;
          }
          $("table#timeline-table").append(item.html);
        }
        self.options.offset = self.options.offset + res.count;
      } else {
        $("#load-more").text("No more items.").prop("disabled", true);
      }
    })
  }

  return TimeLine;
})(jQuery);
