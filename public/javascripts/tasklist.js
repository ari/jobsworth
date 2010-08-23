// -------------------------
//  Task edit
// -------------------------

function loadTask(id) {
	jQuery("#task").fadeOut();
	jQuery.get("/tasks/edit/" + id, {}, function(data) {
		jQuery("#task").html(data);
		jQuery("#task").fadeIn('slow');
		init_task_form();
  });
}


// -------------------------
//  Task list grid
// -------------------------


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

function tasklistReload() {
	jQuery("#task_list").trigger("reloadGrid");
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

var colModel; // we need a global variable to put the model into
var currentSort;

// get the column definition as early as possible
jQuery.getJSON('/users/get_tasklistcols', {}, function(data) {
	colModel = data.colModel;
	currentSort = data.currentSort;
	initTaskList();
	resizeGrid(); // using this instead of autowidth since it seems to behave better
});

function initTaskList() {
	jQuery('#task_list').jqGrid({
		url : '/tasks/list?format=json',
		datatype: 'json',
		jsonReader: {
			root: "tasks.rows",
			repeatitems:false
		},
		colModel : colModel,
		loadonce: false,
		sortable : function(permutation) { taskListConfigSerialise(); }, // re-order columns
		sortname: currentSort.column,
		sortorder: currentSort.order,
		
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
		
		height: 300,
		width: 500,
		
		grouping: true,
		groupingView: {
			groupField: ["milestone"]
		}
	});
	
	
	jQuery('#task_list').navGrid('#task_pager', {refresh:true, search:false, add:false, edit:false, view:false, del:false},
		{}, // use default settings for edit
		{}, // use default settings for add
		{}, // use default settings for delete
		{}, // use default settings for search
		{} // use default settings for view
	);
	
	jQuery("#task_list").jqGrid('sortableRows');
	
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
	
	jQuery("#task_list").jqGrid('navButtonAdd','#task_pager', {
    caption: "Save filter",
    title: "Save filter",
    onClickButton : function () {
      jQuery.nyroModalManual( {
      	url: '/task_filters/new'
			});
    }
	});
	
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
}


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