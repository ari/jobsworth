var INTERVAL = 60000; // runs every minute

// TODO what should it do?
// * it should update the "inline timer" regularly
// * in some conditions:
// * only if the task has been created already
// *
var $minutes,
    $hours;

// it should pause the timer and then hide itself to show the play button
var update_displayed_time = function() {
    var current_minutes = parseInt($minutes.text(), 10),
        current_hours   = parseInt($hours.text(), 10);

    current_minutes++;

    if (current_minutes > 59) {
        current_minutes = 0;
        current_hours++;
    }

    $minutes.text(current_minutes);
    $hours.text(current_hours);
};

jQuery(document).ready(function($) {
    // timers
    var inline = $('#timer-bar-elapsed'),
        $timer;

    // timer spans
    $minutes = $('#minutes > .timer-val');
    $hours   = $('#hours > .timer-val');

    // buttons
    var $pause_button = $('#pause-btn'),
        $play_button  = $('#play-btn'),
        $pin_button   = $('#pin-btn'),
        $save_button  = $('#save-btn'),
        $save_dropdown = $('#save-dropdown'),

    // init timer
    $timer = $.timer(function() {
      update_displayed_time();
    });

    // bindings
    $pause_button.bind('click', function() {
        $timer.pause();
        $(this).hide();
        $play_button.show();
    });

    // it should restart the timer and then hide itself to show the pause button
    $play_button.bind('click', function() {
        $timer.play();
        $(this).hide();
        $pause_button.show();
    });

    // initial timer values
    $minutes.text('00');
    $hours.text('00');

    // TODO when should it start?
    $timer.set({ time: INTERVAL, autostart: true });
    $play_button.hide();
    $save_dropdown.hide();
});
