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

/*
  Loads the task information for the task and displays 
it in the current page.
*/
function showTaskInPage(rowid) {
	jQuery('#task_list').setCell(rowid, 'read', true);
	jQuery('#task_list>tbody>tr#' + rowid).removeClass('unread');
	
    jQuery("#task").fadeOut();
    jQuery.get("/tasks/edit/" + rowid, {}, function(data) {
		jQuery("#task").html(data);
		jQuery("#task").fadeIn('slow');
    });
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
		data: { model : JSON.parse(JSON.stringify(model))}, // this code is mad, but it makes it work on Chrome/Firefox
		dataType: 'json',
		success: function(msg) {
			alert( "Data Saved: " + msg );
		}
	});

}

// initialise the task list table
jQuery(document).ready(function() {
	jQuery.getJSON('/users/get_tasklistcols', {}, initTaskList);
});

function initTaskList(colModel, textStatus) {

	jQuery('#task_list').jqGrid({
		url:'/tasks/list?format=xml',
		datatype: 'xml',
		xmlReader: {
			row:"task",
			repeatitems:false
		},
		colModel : colModel,
		loadonce: false, // force sorting to happen in the browser
		sortable : function(permutation) { taskListConfigSerialise(); }, // re-order columns
		sortname: 'id',
		autowidth: true,
		caption: "Tasks",
		viewrecords: true,
		multiselect: false,
		
		afterInsertRow : setRowReadStatus,
		onSelectRow: showTaskInPage,
		resizeStop: taskListConfigSerialise,
			
		pager: '#task_pager',
		emptyrecords: 'No tasks found.',
		pgbuttons:false,
		pginput:false,
		rowNum:200,
		recordtext: '{2} tasks found.',
		
		height: "300px"
	});
	
	
	jQuery('#task_list').navGrid('#task_pager', {refresh:true, search:false, add:false, edit:false, view:false, del:false}, 
		{}, // use default settings for edit
		{}, // use default settings for add
		{}, // use default settings for delete
		{}, // use default settings for search
		{} // use default settings for view
	);
	
	jQuery("#task_list").jqGrid('sortableRows'); 
	
	jQuery("#task_list").jqGrid('gridResize',{minHeight:150, maxHeight:1000});
	
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
			Shadowbox.open({
	        content:    '/task_filters/new',
	        player:     "iframe",
	        height:     300,
	        width:      460
	    	});
		}
	});
	
	
	jQuery.extend(jQuery.fn.fmatter , {
		daysFromNow : function(cellvalue, options, rowdata) {
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
	});
	
	jQuery.extend(jQuery.fn.fmatter , {
		tasktime : function(cellvalue, options, rowdata) {
			if (cellvalue == 0) {
				return "";
			}
			return Math.round(cellvalue/6)/10 + "hr";
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

// -------------------------


// -------------------------
//  Task list grid
// -------------------------


jQuery(document).ready(function() {

    jQuery('#calendar').fullCalendar({
        events: "/tasks/calendar"

    });

});