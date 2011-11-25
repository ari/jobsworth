var INTERVAL = 60000; // runs every minute
from_dropdown = null;

// TODO what should it do?
// * it should update the "inline timer" regularly
// * in some conditions:
// * only if the task has been created already
// *
var $minutes,
    $hours;

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
        $pin_button   = $('#pin-btn');

    var $save_button  = $('#save-btn'),
        $dropdown = $('#save-dropdown'),
        $li_elapsed = $('#worklog-elapsed'),
        $li_custom = $('#worklog-custom'),
        $li_none = $('#worklog-none'),
        $dialog = $('#worktime_container'),
        $form = $('#taskform');

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

    // it restarts the timer and then hides itself to show the pause button
    $play_button.bind('click', function() {
        $timer.play();
        $(this).hide();
        $pause_button.show();
    });

    // initial timer values
    $minutes.text('00');
    $hours.text('00');

    // make it look like a submit button
    $save_button.addClass("ui-button ui-widget ui-state-default ui-corner-all");

    $form.submit(function(event) {
        var elapsed = $('#timer-bar-elapsed').text();
        // show elapsed in drop-down list
        $('#worklog-elapsed > a').text(elapsed);
        // show drop-down
        $dropdown.toggle('blind');

        // prevent submit
        if (!from_dropdown) {
            event.preventDefault();
            event.stopPropagation();
        }
        from_dropdown = false;
    });

    // set up elements

    var buttons = [
        {
            text: 'Save',
            click: function() {
                $('input', $(this)).clone().appendTo($form);
                from_dropdown = true;
                $form.submit();
                $(this).dialog('close');
            }
        },
        {
            text: 'Cancel',
            click: function() { $(this).dialog('close'); }
        }
    ];

    //set up dialog
    $dialog.dialog({
        autoOpen: false,
        buttons: buttons,
        draggable: false,
        title: 'Crete work log'
    });

    // drop-down elements behaviour
    $li_elapsed.click(function() {
        // get input element from dialog, and append a clone to form
        // we have to do this, because the dialog lives outside of the form
        var elapsed = $('#timer-bar-elapsed').text(),
            $input = $('div[role=dialog] input#work_log_duration'),
            $clone = $input.clone();

        // remove previously appended elements, if any
        remove_residue();
        $clone.val($.trim(elapsed));
        $clone.appendTo($form);

        from_dropdown = true;
        $form.submit();
        $dropdown.toggle('blind');
    });
    $li_custom.click(function() {
        remove_residue();
        $dialog.dialog('open');
    });
    $li_none.click(function() {
        remove_residue();
        from_dropdown = true;
        $form.submit();
        $dropdown.toggle('blind');
    });

    // remove previously appended elements from form
    var remove_residue = function() {
        var $residue = $('#taskform input[name^=work_log]');
        $residue.remove();
    };

    $timer.set({ time: INTERVAL, autostart: true });
});
