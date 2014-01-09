// This file is forked and modified from slick.columnpicker.js from SlickGrid
// Works with stylesheet slick.columnpicker.css

var jobsworth = jobsworth || {}
jobsworth.grids = jobsworth.grids || {}

jobsworth.grids.ColumnPicker = (function ($) {
  function ColumnPicker(columns, grid, options) {
    var $menu;
    var columnCheckboxes;
    var groupByOptions = $('input#groupByOptions').val();
    var columnList;
    var gear_icon = '<i title="Select Columns" class="icon-cog pull-right"></i>';
    var gear_column_id = 'gear_icon';
    var gear_column = {id: gear_column_id, name: gear_icon, field: '', resizable: false, sortable: false, width: 16 }

    var defaults = {
      fadeSpeed:250
    };

    function init() {
      // Add the gear column
      columns.push(gear_column);
      grid.setColumns(columns);

      // Avoid a chicken-egg problem in which the Gear icon column itself is hidden.
      // This may happen, say when this change is deployed for the first time, and 'grid.Columns' is already set in store from previous session.
      if(store.get('grid.Columns') && $.grep(store.get('grid.Columns'), function (e) { return e.id == gear_column_id }).length == 0) {
        // reset
        store.remove('grid.Columns');
      }

      grid.onHeaderClick.subscribe(handleHeaderClick);
      options = $.extend({}, defaults, options);
	  
      $menu = $("<span class='slick-columnpicker' style='display:none;position:absolute;z-index:20;'/>").appendTo(document.body);

      $menu.bind("mouseleave", function (e) {
        $(this).fadeOut(options.fadeSpeed)
      });
      //$menu.bind("click", updateColumn);

    }

    function handleHeaderClick(e, args) {
      var column = args.column;
      if (column.id != gear_column_id) {
        return;
      }

      e.preventDefault();
      $menu.empty();
      columnCheckboxes = [];
      columnList = "";

      var $div, $input;
      for (var i = 0; i < columns.length; i++) {
        // the gear icon is not unselectable
        if(columns[i].id == gear_column_id) {
          continue;
        }

        $div = $("<div />");//.appendTo($menu);
        $input = $("<input type='checkbox' id='col_visibility' />").data("column-id", columns[i].id);
        columnCheckboxes.push($input);

        if (grid.getColumnIndex(columns[i].id) != null) {
          $input.attr("checked", "checked");
        }

        $("<label>" + columns[i].name + "</label>" )
            .prepend($input)
            .appendTo($div);
        columnList += $div[0].outerHTML;
      }
      
      $("<div id='columnList'>Visible columns</div>").appendTo($menu);
	  $("<div id='groupByList'>Grouped by</div>").appendTo($menu);
	  	
      $menu
          .css("top", e.pageY - 10)
          .css("left", e.pageX - 10)
          .fadeIn(options.fadeSpeed);
      
      $("#columnList").popover({
	    trigger: "manual",
	    container: 'body',
	    html: true,
	    placement: 'left',
	    content: columnList
	  });
	
	  $("#groupByList").popover({
	    trigger: "manual",
	    container: 'body',
	    html: true,
	    placement: 'left',
	    content: groupByOptions
	  });
	  
	  $("#columnList").hover(function(){
	  	$("#columnList").popover('show');
	  	$("#groupByList").popover('hide');
	  	//$("#columnList").live("mouseleave", function () {
          //$("#columnList").popover('hide');
        //});
	  });
	  
	  $("#groupByList").hover(function(){
	  	$("#groupByList").popover('show');
	  	$("#columnList").popover('hide');
	  	//$("#groupByList").live("mouseleave", function () {
          //$("#groupByList").popover('hide');
        //});
	  });
	  
	  //$("#columnList").find('.popover-content').live("mouseleave", function () {
        //  $("#columnList").popover('hide');
      //});
	  
	  //$("#groupByList").find('.popover-content').live("mouseleave", function () {
        //  $("#groupByList").popover('hide');
      //});
	  
	  $('#col_visibility').live('click',function(){
	  	updateColumn();
	  });
    }
	
    //function updateColumn(e) {
    //  if ($(e.target).is(":checkbox")) {
    //    var visibleColumns = [];
    //    $.each(columnCheckboxes, function (i, e) {
    //      if ($(this).is(":checked")) {
    //        visibleColumns.push(columns[i]);
    //      }
    //    });

        // gear column is always displayed
    //    visibleColumns.push(gear_column);

   //     grid.setColumns(visibleColumns);
   //     grid.onColumnsResized.notify();
   //   }
   // }
    
    function updateColumn() {
      var visibleColumns = [];
      $.each($('input#col_visibility'), function (i, e) {       	
        if ($(this).is(":checked")) {
          visibleColumns.push(columns[i]);
        }
      });

      // gear column is always displayed
      visibleColumns.push(gear_column);
      grid.setColumns(visibleColumns);
      grid.onColumnsResized.notify();
    }

    init();
  }

  return ColumnPicker;
})(jQuery);
