// -------------------------
//  Task list grid
// -------------------------

// the column model which we want to cache on the browser
var columnModel;

/*
  Sends an ajax request to save the given user preference to the db
*/
function saveUserPreference(name, value) {
        var params = { "name": name, "value": value };
        jQuery.post("/users/set_preference",  params);
}
function getUserPreference(name) {
  var url = "/users/get_preference?name=" + name;
  jQuery.post("/users/set_preference",  params);
}

function selectRow(rowid) {
        jQuery('#task_list').setCell(rowid, 'read', true);
        jQuery('#task_list>tbody>tr#' + rowid).removeClass('unread');
        loadTask(rowid);
}

function setRowReadStatus(rowid, rowdata) {
        if (rowdata.read == 'f') {
                jQuery('#task_list>tbody>tr#' + rowid).addClass('unread');
        }
}

function taskListConfigSerialise() {
        var model = jQuery("#task_list").jqGrid('getGridParam', 'colModel');

        jQuery.ajax({
                type: "POST",
                url: '/users/set_tasklistcols',
                data: { model : JSON.stringify(model)},
                dataType: 'json',
                success: function(msg) {
                        alert( "Data Saved: " + msg );
                }
        });
}

var group_value = ""
function change_group() {
  var vl = jQuery("div.ui-pg-div > #chngroup").val();
  if(vl) {
    if(vl == "clear") {
      jQuery("#task_list").jqGrid('groupingRemove',true);
    } else {
      jQuery("#task_list").jqGrid('groupingGroupBy',vl);
    }
  }
  jQuery.post("/users/set_task_grouping_preference/" +  vl);
  group_value = vl;
}


/* Since the json call is asynchronous
  it is important that this function then calls
  the initGrid to finish loading the grid,
  but only after it has returned successfully
*/
jQuery(document).ready(function() {
  jQuery.ajax({
    async: false,
    url: '/users/get_tasklistcols',
    dataType: 'json',
    success:function(response) {
      columnModel = response;
      initTaskList();
    },
    error:function (xhr, thrownError) {
      alert("Invalid task list model returned from server");
    }
  });
});

function initTaskList() {
  jQuery('#task_list').jqGrid({
        url : '/tasks/list?format=json',
        datatype: 'json',
        jsonReader: {
                root: "tasks.rows",
                repeatitems:false
        },
        colModel : columnModel.colModel,
        loadonce: false,
        sortable : function(permutation) { taskListConfigSerialise(); }, // re-order columns
        sortname: columnModel.currentSort.column,
        sortorder: columnModel.currentSort.order,

        caption: "Tasks",
        viewrecords: true,
        multiselect: false,

        afterInsertRow : function(rowid, rowdata, rowelem) { setRowReadStatus(rowid, rowdata); },
        onSelectRow: function(rowid, status) { selectRow(rowid); },
        resizeStop: function(newwidth, index) { taskListConfigSerialise(); },
        shrinkToFit: true,

        pager: '#task_pager',
        emptyrecords: 'No tasks found.',
        pgbuttons:false,
        pginput:false,
        rowNum:200,
        recordtext: '{2} tasks found.',

        footerrow: true,
        userDataOnFooter: true,
        userdata: "userdata",

        height: 300,
        width: 500,

        grouping: jQuery("#chngroup").val() != "clear",
        groupingView: {
           groupField: [jQuery("#chngroup").val()]
        }
  });

  jQuery('#task_list').navGrid('#task_pager', {refresh:true, search:false, add:false, edit:false, view:false, del:false},
        {}, // use default settings for edit
        {}, // use default settings for add
        {}, // use default settings for delete
        {}, // use default settings for search
        {} // use default settings for view
  );

  jQuery("#task_list").jqGrid('sortableRows', {
    update: function(event, ui) {
    if (jQuery("#chngroup").val() != "clear") {
                var id = ui.item.index();
                for (i=id;i>=0;i--) {
                        if (jQuery("tbody.ui-sortable > tr.ui-widget-content").eq(i-1).attr("id").match(/task_listghead/) != null) {
                var group_id = jQuery("tbody.ui-sortable > tr.ui-widget-content").eq(i-1).attr("id");
                        var group_text = jQuery("#" + group_id + " > td").text();
                var group_icon;
                if (group_text == "") {
                        group_icon = jQuery("#" + group_id + " > td > span > img").attr("src");
                }
                        break;
                        }
                }
                if (group_value != "") {
                        var group = group_value;
                } else {
                        var group = jQuery("#chngroup").val();
                }
                jQuery.post("/tasks/set_group/"+ ui.item.attr("id") +"?group=" +  group + "&value=" + group_text+ "&icon=" + group_icon);
        if (group_text != "") {
                jQuery('.ui-sortable > tr#'+ ui.item.attr("id") +' > td[aria-describedby=\"task_list_'+ group + '\"]').text(group_text);
                jQuery('.ui-sortable > tr#'+ ui.item.attr("id") +' > td[aria-describedby=\"task_list_'+ group + '\"]').attr('title', group_text);
        } else if(group_icon != undefined) {
                var image = jQuery("#" + group_id + " > td").html();
                jQuery('.ui-sortable > tr#'+ ui.item.attr("id") +' > td[aria-describedby=\"task_list_'+ group + '\"]').html(image);
                jQuery('.ui-sortable > tr#'+ ui.item.attr("id") +' > td[aria-describedby=\"task_list_'+ group + '\"] > span.ui-icon').remove();
        }
        }
    }
  });

  jQuery("#task_list").jqGrid('gridResize', {
        stop: function(event, ui) {
                resizeGrid(); // force width
    },
    minHeight: 150,
    maxHeight: 1000
  });

  jQuery("#task_list").jqGrid('navButtonAdd','#task_pager', {
        caption: "Columns",
        title: "Show/hide columns",
        onClickButton : function () {
                jQuery("#task_list").jqGrid('columnChooser');
                taskListConfigSerialise();
        }
  });

  jQuery("#task_list").jqGrid('navButtonAdd','#task_pager', {
        caption: "Export",
        title: "Export data to CSV",
        onClickButton : function () {
      window.location.href="/tasks/get_csv";
        }
  });

  appendPartial("/task_filters/new", '#savefilter', false);
  jQuery("#task_list").jqGrid('navButtonAdd','#task_pager', {
    caption: "Save filter",
    title: "Save filter",
    onClickButton : function () {
      var dialog = jQuery("#savefilter").dialog({
        width: 400,
            autoOpen: false,
            title: 'Save Filter',
        draggable: true
          });
          dialog.dialog('open');
          return false;
    }
  });

  jQuery("#task_list").jqGrid('navButtonAdd','#task_pager', {
      caption: jQuery("#groupby").html(),
      buttonicon: "none",
      id: "jgrid_footer_changegroup"
  });
  jQuery('#task_pager_center').remove();
  resizeGrid();
}

jQuery.extend(jQuery.fn.fmatter , {
  daysFromNow : function(cellvalue, options, rowdata) {
    var val = dueTaskValue(cellvalue);
    return val;
  }
});

jQuery.extend(jQuery.fn.fmatter , {
  tasktime : function(cellvalue, options, rowdata) {
    var val = timeTaskValue(cellvalue);
    return val;
  }
});

jQuery.extend(jQuery.fn.fmatter , {
  read : function(cellvalue, options, rowdata) {
    if (cellvalue == 't') {
      // TODO
      // the next javascript in the next line doesn't work because the selecting the row marks the task as read
      return "<a href='#' onclick='toggleTaskUnread();'><span class='unread_icon'/></a>";
    }
    return "<span class='unread_icon'/>";
  }
});


jQuery(window).bind('resize', function() {
  resizeGrid();
});

function resizeGrid() {
  jQuery("#task_list").setGridWidth(jQuery(window).width() - 220); //allow for sidebar and margins
}

// -------------------------
//  Calendar
// -------------------------


jQuery(document).ready(function() {

  jQuery('#calendar').fullCalendar({
    events: "/tasks/calendar",
      theme: true,
      height: 350,

      eventClick: function(calEvent, jsEvent, view) {
        loadTask(calEvent.id);
      },

      editable: true,
      disableResizing: true,
      eventDrop: function(event,dayDelta,minuteDelta,allDay,revertFunc) {
        // FIXME: needs ajax callback to update task date
      }

        });
});

function dueTaskValue(cellvalue) {
        if (cellvalue == "") {
            return "";
        }
        var one_day=1000*60*60*24;
        var days = Math.round( (new Date(cellvalue * 1000) - new Date().getTime()) /one_day);
        if (days == 0) {
    return "<span class='due_today'>today</span>";
        }
        if (days == 1) {
    return "<span class='due_future'>tomorrow</span>";
        }
        if (days == -1) {
    return "<span class='due_past'>" + "yesterday</span>";
        }
        if (days > 548) {
    return "<span class='due_future'>" + Math.round(days/365) + " years</span>";
        }
        if (days < -548) {
    return "<span class='due_past'>" + Math.round(-days/365) + " years ago</span>";
        }
        if (days > 50) {
    return "<span class='due_future'>" + Math.round(days/30.4) + " months</span>"; // average number of days in a month
        }
        if (days < -50) {
    return "<span class='due_past'>" + Math.round(-days/30.4) + " months ago</span>";
        }
        if (days > 14) {
    return "<span class='due_future'>" + Math.round(days/7) + " weeks</span>";
        }
        if (days < -14) {
    return "<span class='due_past'>" + Math.round(-days/7) + " weeks ago</span>";
        }
        if (days > 0) {
    return "<span class='due_future'>" + days + " days</span>";
        }
        return "<span class='due_past'>" + -days + " days ago</span>";
}

function timeTaskValue(cellvalue) {
        if (cellvalue == 0) {
          return "";
        }
        return Math.round(cellvalue/6)/10 + "hr";
}

function tasksViewReload()
{
    jQuery("#task_list").trigger("reloadGrid");
    jQuery('#calendar').fullCalendar('refetchEvents');
}