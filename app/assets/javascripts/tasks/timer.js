var jobsworth = jobsworth || {}
jobsworth.tasks = jobsworth.tasks || {}

jobsworth.tasks.TaskTimer = (function(){

  function bind() {
      var $ = jQuery;
      var self = this;

      // buttons
      var $inline = $('#timer-bar-elapsed'),
          $pause_button = $('#pause-btn'),
          $play_button  = $('#play-btn'),
          $pin_button   = $('#pin-btn'),
          $save_button  = $('#save-btn'),
          $li_elapsed = $('#worklog-elapsed'),
          $li_custom = $('#worklog-custom'),
          $li_none = $('#worklog-none'),
          $dialog = $('#worktime-dialog'),
          $form = $('#taskform');

      // initialize modal
      $dialog.draggable({handle: '.modal-header'});

      // bind dropdown
      $('.dropdown-toggle').dropdown();

      // bindings
      $pause_button.bind('click', function() {
          self.total_milliseconds += (new Date() - self.last_start_point);

          clearInterval(self.timer);
          $(this).hide();
          $play_button.show();

          return false;
      });

      $('#worklog-property ul li').bind('click', function() {
          var id = $(this).attr("data_id");
          $("#worklog-property input#choice-id").val(id);
          $('#selected-worklog-property').html($(this).text() + "<b class=\"caret\"></b>");
          $('#worklog-property').removeClass('open');
          return false;
      })

      // it restarts the timer and then hides itself to show the pause button
      $play_button.bind('click', function() {
          self.last_start_point = new Date();

          self.timer = setInterval( function() { pulse.call(self) }, self.INTERVAL);
          $(this).hide();
          $pause_button.show();

          return false;
      });

      // drop-down elements behaviour
      $li_elapsed.click(function() {
          var minutes = Math.floor(self.total_milliseconds / 60000 ) % 60;
          var hours = Math.floor(self.total_milliseconds / 3600000);

          $('#taskform input[name="work_log[duration]"]').val(hours + 'h' + minutes + 'm');
          $form.submit();
      });

      $li_none.click(function() {
          $('#taskform input[name="work_log[duration]"]').remove();
          from_dropdown = true;
          $form.submit();
      });

      // show dropdown
      $save_button.click(function() {
          var minutes = Math.floor(self.total_milliseconds / 60000 ) % 60;
          var hours = Math.floor(self.total_milliseconds / 3600000);

          var hour_unit = hours > 1 ? "hours" : "hour";
          var minute_unit = minutes > 1 ? "minutes" : "minute";

          // show elapsed in drop-down list
          if (hours > 0) {
              $('#worklog-elapsed > a').text(hours + " " + hour_unit + " " + minutes + " " + minute_unit);
          } else {
              $('#worklog-elapsed > a').text(minutes + " " + minute_unit);
          }

          return false;
      });


      $("button.save", $dialog).click(function(e) {
        $('input[name^="work_log"]', $form).remove();
        $dialog.modal('hide');
        $dialog.addClass("none").appendTo($form);
        $form.submit();
        return false;
      })
  }

  function pulse() {
      var new_start_point = new Date();
      this.total_milliseconds += (new_start_point - this.last_start_point);
      this.last_start_point = new_start_point;

      var minutes = Math.floor(this.total_milliseconds / 60000 ) % 60;
      var hours = Math.floor(this.total_milliseconds / 3600000);
      var hour_unit = hours > 1 ? "hours" : "hours";
      var minute_unit = minutes > 1 ? "minutes" : "minute";

      jQuery('#hours .unit').text(hour_unit);
      jQuery('#minutes .unit').text(minute_unit);
      this.$minutes.text(minutes);
      this.$hours.text(hours);

      if (hours > 0) {
          jQuery('#hours').show();
      } else {
          jQuery('#hours').hide();
      }
  }

  function destroy() {
      clearInterval(this.timer);
  }

  function init() {
      this.INTERVAL = 60000; // runs every minute
      this.timer = null;
      this.total_milliseconds = 0;
      this.last_start_point = new Date();

      this.$minutes = jQuery('#minutes > .timer-val');
      this.$hours   = jQuery('#hours > .timer-val');
      jQuery('#hours').hide();

      // initial timer values
      this.$minutes.text('0');
      this.$hours.text('0');

  }

  function TaskTimer() {
      init.call(this);
      bind.call(this);

      //public methods
      this.destroy = destroy;

      // init timer
      var self = this;
      this.timer = setInterval(function(){ pulse.apply(self) }, this.INTERVAL);
  }

  return TaskTimer;
})();
