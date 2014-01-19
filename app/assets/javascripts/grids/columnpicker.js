// This file is forked and modified from slick.columnpicker.js from SlickGrid
// Works with stylesheet slick.columnpicker.css

var jobsworth = jobsworth || {}
jobsworth.grids = jobsworth.grids || {}

jobsworth.grids.ColumnPicker = (function ($) {
  function ColumnPicker(columns, grid, options) {
    var $menu;
    var columnCheckboxes;
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
      	  
	  grid.onHeaderMouseEnter.subscribe(handleHeaderHover);	
	  
	  grid.onHeaderMouseLeave.subscribe(function(e, args){
	  	setTimeout(function (){
	  	  if($('.cogwheel-menu:hover').length == 0) {
	  	    $('.cogwheel-menu').fadeOut(options.fadeSpeed); 
	  	  }
	  	}, 300);
	  });
      
      options = $.extend({}, defaults, options);
	  $menu = $("<span class='dropdown' style='display:none;position:absolute;z-index:20;'/>").appendTo(document.body);
    }

    function handleHeaderHover(e, args) {
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

        $li = $("<li />");
        $input = $("<input type='checkbox' style='vertical-align: baseline' id='col_visibility' />").data("column-id", columns[i].id);
        columnCheckboxes.push($input);

        if (grid.getColumnIndex(columns[i].id) != null) {
          $input.attr("checked", "checked");
        }

        $("<label>" + columns[i].name + "</label>" )
            .prepend($input)
            .appendTo($li);
        columnList += $li[0].outerHTML;
      }
	  
	  $('.cogwheel-menu').clone().appendTo($menu);
      $menu.find('.cogwheel-menu').show();
      $('.cogwheel-menu >li >ul').hide();
      $('.column-visibility').html(columnList);
	    
      $menu
          .css("top", '172px')
          .css("left", '1080px')
          .fadeIn(options.fadeSpeed);
      
      $(".columnList").hover(function(){
    	$(".columnList >ul").show();
    	$(".groupByOptions >ul").hide();
      });
      
      $(".groupByOptions").hover(function(){
    	$(".groupByOptions >ul").show();
    	$(".columnList >ul").hide();
      });
      
      $('.cogwheel-menu').on('mouseleave', function() {
      	$(this).fadeOut(options.fadeSpeed);
      });
       
	  $('.column-visibility').live('click',function(){
	  	updateColumn();
	  });
    }    
    
    function updateColumn() {
      var visibleColumns = [];
      $.each($('.dropdown').find('input#col_visibility'), function (i, e) {  
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
