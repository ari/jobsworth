
var jobsworth = jobsworth || {};

jobsworth.Filter = (function($){
  function Filter() {
    this.init();
    this.bind();
  }
    Filter.prototype.init = function() {
    var self = this;

    $('#search_filter').catcomplete({
      source: '/task_filters/search',
      select: function(event, ui) {
        self.addSearchFilter(event, ui);
        $(this).val("");
        return false;
      },
      delay: 800,
      minLength: 3
    });
  };

  Filter.prototype.bind = function() {
    var self = this;

    // make search box contents selected when the user clicks in it
    $("#search_filter").focus( function() {
      $(this).select();
    });

    // the user/client search box
    $(".search_filter").focus( function() {
      $(this).select();
    });

    // Go to a task immediately if a number is entered and then the user hits enter
    $("#search_filter").keypress(function(key) {
      if (key.keyCode == 13) { // if key was enter
        var id = $(this).val();
        if (id.match(/^\d+$/)) {
          new jobsworth.Task(task.id);
        }
      }
    });

    $('.task_filters>ul>li>a').click(function() {
      self.loadFilter('', this.href);
      return false;
    });

    $('#tags .panel_content a').click(function() {
      self.loadFilter('', this.href);
      return false;
    });

    $("#search_filter_form").submit(function(event){
      self.loadFilter($.param($(this).serializeArray()), "/task_filters/update_current_filter");
      return false;
    });

    $(".action_filter").live('click', function() {
      self.actionFilterClick(this);
    });

    $("#savefilter_link").click(function() {
      self.saveFilter();
      return false;
    });

    $(".collapsable-sidepanel-button").live('click', function() {
      self.collapseSidePanel(this);
      return false;
    });

    $(".remove-search-filter").live('click', function() {
      self.removeSearchFilter(this);
      return false;
    });

    $(".reverse-filter-item-link").live('click', function() {
      self.reverseSearchFilter(this);
      return false;
    })
  };

  /*
  Removes the search filter the link belongs to and submits
  the containing form.
  */
  Filter.prototype.removeSearchFilter = function(link) {
    $(link).parents("li").remove();
    $("#search_filter_form").trigger('submit');
  };

  Filter.prototype.reverseSearchFilter = function(link) {
    var input = $(link).siblings("input.reversed");
    if (input.val() == "false") {
      input.val("true");
    } else {
      input.val("false");
    }
    $("#search_filter_form").trigger('submit');
  };

  Filter.prototype.loadFilter = function(data, url){
    $.ajax({
      complete: function(request){
        if (grid) grid.reload();
      },
      data: data,
      success: function(request){
        $('#search_filter_keys').html(request).effect("highlight", {color: '#FF9900'}, 3000);
      },
      type:'post',
      url: url
    });
    return false;
  };

  /* This function add inputs to search filter form, it works in both cases via normal http post and via ajax
  */
  Filter.prototype.addSearchFilter = function(event, ui) {
    var selected = ui.item;
    var idName = selected.id;
    var idValue = selected.idval;
    /*NOTE: if user select qulifier, than idName -> name of param qualifier_id
      idValue -> value of this param, etc.
      else if user select keyword, then idName -> name of keyword_id or unread_only  param, idValue-> value of  param,
      but type&column name/value not exist
    */
    var typeName = selected.type;
    var typeValue = selected.typeval;
    var columnName = selected.col;
    var columnValue = selected.colval;
    var reversedName = selected.reversed;
    var reversedVal = selected.reversedval;
    if (idName && idName.length > 0) {
      var filterKeys = $("#search_filter_form ul#search_filter_keys");
      filterKeys.append('<input type="hidden" name="'+idName+'" value="'+idValue+'"/>');
      if (typeName && typeName.length>0){
          filterKeys.append('<input type="hidden" name="'+typeName+'" value="'+typeValue+'"/>');
      }
      if (columnName && columnName.length>0) {
          filterKeys.append('<input type="hidden" name="'+columnName+'" value="'+columnValue+'"/>');
      }
      if (reversedName && reversedName.length > 0) {
          filterKeys.append('<input type="hidden" name="'+reversedName+'" value="'+reversedVal+'"/>');
      }
      $("#search_filter_form").trigger('submit');
    } else {
        // probably selected a heading, just ignore
    }
  };

  Filter.prototype.actionFilterClick = function(link) {
    var sender = $(link);
    var tf_id = sender.parent().parent().attr("id").split("_")[1];
    var senderParentClass = sender.parent().attr('class');
    if(sender.hasClass('do_hide') || sender.hasClass('do_show')) {
      var url = "/task_filters/" + tf_id + "/toggle_status";
      var type = "get";
    } else if (sender.hasClass('do_delete')) {
      var warning = confirm("Are you sure to delete this filter?");
      if(!warning) { return false; }
      var url = "/task_filters/" + tf_id;
      var type = "delete";
    }
    $.ajax({
      url: url,
      dataType: 'html',
      type: type,
      success:function(response) {
        $("#task_filters").replaceWith(response);
        if (sender.hasClass('do_hide')) {
          sender.replaceWith("<a href='#' class='action_filter do_show'>Show</a>");
        } else if (sender.hasClass('do_show')) {
          sender.replaceWith("<a href='#' class='action_filter do_hide'>Hide</a>");
        } else if (sender.hasClass('do_delete')) {
          sender.parent().parent().remove();
        }
      },
      error:function (xhr, thrownError) {
        alert("Invalid request");
      }
    });
  };

  Filter.prototype.saveFilter = function() {
    if ($("#save-current-filter-dialog").length == 0) {
      $.get("/task_filters/new", function(data) {
        $('body').append(data);
        $('#save-current-filter-dialog').modal({backdrop: false})
      }, 'html')
    } else {
      $('#save-current-filter-dialog').modal({backdrop: false})
    }
    $('#filters-menu').toggleClass("open");
  };

  Filter.prototype.collapseSidePanel = function(link) {
    var panel = $(link).parent().attr("id");
    if ($(link).hasClass("panel-collapsed")) {
      store.remove('sidepanel_' + panel);
      $('div#' + panel +' .panel_content').show();
      $(link).attr("class", "collapsable-sidepanel-button panel-open")
    }
    else {
      store.set('sidepanel_' + panel, 'h');
      $('div#' + panel +' .panel_content').hide();
      $(link).attr("class", "collapsable-sidepanel-button panel-collapsed")
    }
  };

  return Filter;
})(jQuery);


function removeTaskFilter(sender) {
  var li = jQuery(sender).parent();
  var form = li.parents("form");
  li.remove();
  form.submit();
}

function addTaskFilter(sender, id, field_name) {
  var li = jQuery(sender);
  var html = "<input type='hidden' name='" + field_name + "' value='" + id + "' />";
  li.append(html);
  jQuery("#filter_form").submit();
}

jQuery(document).ready(function () {
  jQuery("#tags-collapsable-sidepanel-button").on('click', function() {
    if (store.get('tags-collapsable-sidepanel-button') == 'h') {
      jQuery("#tags-collapsable-sidepanel-button").addClass('panel-open');
      jQuery("#tags-collapsable-sidepanel-button").removeClass('panel-collapsed');
      jQuery('div#tags .panel_content').show();
      store.remove('tags-collapsable-sidepanel-button');
    }
    else {
      jQuery("#tags-collapsable-sidepanel-button").addClass('panel-collapsed');
      jQuery("#tags-collapsable-sidepanel-button").removeClass('panel-open');
      jQuery('div#tags .panel_content').hide();
      store.set('tags-collapsable-sidepanel-button', 'h');
    }
  });
});

jQuery(document).ready(function () {
  jQuery("#task-filters-collapsable-sidepanel-button").on('click', function() {
    if (store.get('task-filters-collapsable-sidepanel-button') == 'h') {
      jQuery("#task-filters-collapsable-sidepanel-button").addClass('panel-open');
      jQuery("#task-filters-collapsable-sidepanel-button").removeClass('panel-collapsed');
      jQuery('div#task_filters .panel_content').show();
      store.remove('task-filters-collapsable-sidepanel-button');
    }
    else {
      jQuery("#task-filters-collapsable-sidepanel-button").addClass('panel-collapsed');
      jQuery("#task-filters-collapsable-sidepanel-button").removeClass('panel-open');
      jQuery('div#task_filters .panel_content').hide();
      store.set('task-filters-collapsable-sidepanel-button', 'h');
    }
  });
});
