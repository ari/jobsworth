var jobsworth = jobsworth || {}

jobsworth.Grid = (function($){

  var columns = [
    {id: 'read', name: '', field: 'read', width: 16, selectable: false, resizable: false, sortable: true, formatter: UnreadMarkFormatter},
    {id: 'id', name: 'id', field: 'id', minWidth: 30, sortable: true},
    {id: 'summary', name: 'summary', field: 'summary', minWidth: 300},
    {id: 'client', name: 'client', field: 'client', minWidth: 200, sortable: true},
    {id: 'milestone', name: 'milestone', field: 'milestone', minWidth: 150, sortable: true},
    {id: 'due', name: 'target date', field: 'due', minWidth: 60, sortable: true},
    {id: 'time', name: 'time', field: 'time', minWidth: 60, sortable: true, formatter: TimeFormatter},
    {id: 'assigned', name: 'assigned', field: 'assigned', minWidth: 60, sortable: true},
    {id: 'resolution', name: 'resolution', field: 'resolution', minWidth: 60, sortable: true},
    {id: 'updated_at', name: 'last comment date', field: 'updated_at', minWidth: 150, sortable: true},
  ];

  function Grid(options) {
    this.options = options;
    this.init();
  }

  function UnreadMarkFormatter(row, cell, value, columnDef, dataContext) {
    return value == "f" ? "<span class='unread_icon'/>" : "";
  }
  function TimeFormatter(row, cell, value, columnDef, dataContext) {
    if (value == 0) {
      return "";
    } else {
      return Math.round(value/6)/10 + "hr";
    }
  }

  Grid.prototype.init = function() {
    var self = this;

    $.getJSON("/tasks?format=json", function(rows) {
      self.createGrid(rows);
    })
  }

  Grid.prototype.reload = function() {
    var self = this;
    showProgress();
    $.getJSON("/tasks?format=json", function(rows) {
      self.dataView.beginUpdate();
      self.dataView.setItems(rows);
      self.dataView.endUpdate();
      hideProgress();
    })
  }

  Grid.prototype.bind = function() {
    var self = this;

    $("#groupBy").insertBefore(".slick-pager-settings");
    $("#groupBy select").change(function() {
      var value = $(this).val();
      for(var index in columns) {
        if(columns[index].id == value) {
          self.groupBy(columns[index]);
          return;
        }
      }
      self.groupBy(null);
    })

    this.grid.onClick.subscribe(function (e) {
      var cell = self.grid.getCellFromEvent(e);
      var task = self.grid.getDataItem(cell.row);
      self.loadTask(task.id);
    });

    this.grid.onSort.subscribe(function(e, args) {
      self.onSort(e, args); 
    });

    this.dataView.onRowCountChanged.subscribe(function (e, args) {
      self.grid.updateRowCount();
      self.grid.render();
    });

    this.dataView.onRowsChanged.subscribe(function (e, args) {
      self.grid.invalidateRows(args.rows);
      self.grid.render();
    });

    $('#taskform').live("ajax:success", function(event, json, xhr) {
      authorize_ajax_form_callback(json);
      var task = json;
      $('#errorExplanation').remove();
      $("span.fieldWithErrors").removeClass("fieldWithErrors");
      if (task.status == "error") {
        var html = "<div class='errorExplanation' id='errorExplanation'>";
        html += "<h2>"+ task.messages.length +" error prohibited this template from being saved</h2><p>There were problems with the following fields:</p>";
        for (i=0 ; i < task.messages.length ; i++) {html += "<ul><li>"+ task.messages[i] + "</li></ul>";}
        html += "</div>"
        $(html).insertAfter("#task_id");
      }
      else {
        self.reload();
        //update tags
        $("#tags").replaceWith(html_decode(task.tags));
        self.loadTask(task.tasknum);
        flash_message(task.message);
      }
    }).bind("ajax:before", function(event, json, xhr) {
      showProgress();
    }).bind("ajax:complete", function(event, json, xhr) {
      hideProgress();
    }).bind("ajax:failure", function(event, json, xhr, error) {
      alert('error: ' + error);
    });
  }

  Grid.prototype.createGrid = function(rows) {
    var self = this;

    var options = {
      enableCellNavigation: true,
      enableColumnReorder: true,
      multiColumnSort: true,
      forceFitColumns:true
    };

    var groupItemMetadataProvider = new Slick.Data.GroupItemMetadataProvider();
    this.dataView = new Slick.Data.DataView({
      groupItemMetadataProvider: groupItemMetadataProvider,
      inlineFilters: true
    });

    this.grid = new Slick.Grid(this.options.el, this.dataView, columns, options);
    this.grid.setSelectionModel(new Slick.RowSelectionModel());
    this.grid.registerPlugin(groupItemMetadataProvider);
    var pager = new Slick.Controls.Pager(this.dataView, this.grid, $("#pager"));

    // this line must be called before the lines below
    this.bind();

    this.dataView.beginUpdate();
    this.dataView.setItems(rows);
    this.dataView.endUpdate();
    this.grid.autosizeColumns();
    $(this.options.el).resizable({handles: 's, n'});
  }

  Grid.prototype.groupBy = function(column) {
    if (!column) {
      this.dataView.groupBy(null);
      return;
    }

    this.dataView.groupBy(
      column.field,
      function (g) {
        return column.name + ":  " + g.value + "  <span style='color:green'>(" + g.count + " items)</span>";
      },
      function (a, b) {
        return a.value - b.value;
      }
    );
  }

  Grid.prototype.onSort = function (e, args) {
    var cols = args.sortCols;

    this.grid.getData().sort(function (dataRow1, dataRow2) {
      for (var i = 0, l = cols.length; i < l; i++) {
        var field = cols[i].sortCol.field;
        var sign = cols[i].sortAsc ? 1 : -1;
        var value1 = dataRow1[field], value2 = dataRow2[field];
        var result = (value1 == value2 ? 0 : (value1 > value2 ? 1 : -1)) * sign;
        if (result != 0) {
          return result;
        }
      }
      return 0;
    });
    this.grid.invalidate();
    this.grid.render();
  };

  Grid.prototype.loadTask = function(id) {
    if (window.taskTimer) window.taskTimer.destroy();

    $.getJSON("/tasks/edit/" + id, function(data) {
      $("#task").fadeOut();
      $("#task").html(data.html);
      $("#task").fadeIn();
      document.title = "Task " + data.task_num + ":" + data.task_name;
      $("#task [rel=tooltip]").tooltip();
    }, "html");
  }

  return Grid;
})(jQuery);
