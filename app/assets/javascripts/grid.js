var jobsworth = jobsworth || {}

jobsworth.Grid = (function($){

  var columns = [
    {id: 'read', name: "<span class='unread_icon'/>", field: 'read', resizable: false, sortable: true, formatter: UnreadMarkFormatter, width:16},
    {id: 'id', name: 'id', field: 'id', sortable: true},
    {id: 'summary', name: 'summary', field: 'summary', formatter: HtmlFormatter, width:300},
    {id: 'client', name: 'client', field: 'client', sortable: true, formatter: HtmlFormatter},
    {id: 'milestone', name: 'milestone', field: 'milestone', sortable: true, formatter: HtmlFormatter},
    {id: 'due', name: 'target date', field: 'due', sortable: true, formatter: HtmlFormatter},
    {id: 'time', name: 'time', field: 'time', sortable: true, formatter: DurationFormatter},
    {id: 'assigned', name: 'assigned', field: 'assigned', sortable: true},
    {id: 'resolution', name: 'resolution', field: 'resolution', sortable: true},
    {id: 'updated_at', name: 'last comment date', field: 'updated_at', sortable: true, formatter: TimeFormatter}
  ];

  function Grid(options) {
    this.options = options;
    this.init();
  }

  /* formatters for SlickGrid */
  function UnreadMarkFormatter(row, cell, value, columnDef, dataContext) {
    return value == "f" ? "<span class='unread_icon'/>" : "";
  }
  // fix slickgrid displaying html in cell
  function HtmlFormatter(row, cell, value, columnDef, dataContext) {
    return value;
  }
  function DurationFormatter(row, cell, value, columnDef, dataContext) {
    if (value == 0) {
      return "";
    } else {
      if (dataContext.is_default) {
        return "<span class='defaultValue'>" + Math.round(value/6)/10 + "hr (default)</span>";
      } else {
        return Math.round(value/6)/10 + "hr";
      }
    }
  }
  function HtmlFormatter(row, cell, value, columnDef, dataContext) {
    return value;
  }
  function TimeFormatter(row, cell, value, columnDef, dataContext) {
    return $.timeago(value);
  }
  /* end of formatters */

  Grid.prototype.init = function() {
    var self = this;

    $.getJSON("/companies/properties", function(data) {
      for(var index in data) {
        var property = data[index]["property"]
        columns.push({
          id: property.name.toLowerCase(),
          name: property.name.toLowerCase(),
          field: property.name.toLowerCase(),
          sortable: true,
          formatter: HtmlFormatter
        });
      }
      $.getJSON("/tasks?format=json", function(rows) {
        self.createGrid(rows);
      })
    })
  }

  Grid.prototype.reload = function() {
    var self = this;
    $.getJSON("/tasks?format=json", function(rows) {
      self.dataView.setItems(rows);
      self.grid.invalidate();
      self.grid.render();
    })
  }

  Grid.prototype.bind = function() {
    var self = this;

    $("#groupBy select").change(function() {
      var value = $(this).val();
      store.set("grid.groupBy", value)
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

      // mark task as read
      if (task.read == "f") {
        task.read = "t";
        self.dataView.updateItem(task.id, task);
      }

      new jobsworth.Task(task.id);
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

    this.grid.onColumnsReordered.subscribe(function (e, args) {
      store.set('grid.Columns', self.grid.getColumns());
    });

    this.grid.onColumnsResized.subscribe(function (e, args) {
      store.set('grid.Columns', self.grid.getColumns());
    });

    $(window).resize(function () {
      self.grid.resizeCanvas();
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

    // highlight unread line
    this.dataView.getItemMetadata = (function(original_provider){
      return function(row) {
        var item = this.getItem(row),
            ret  = original_provider(row);

        if (item){
          ret = ret || {}
          if (item.read == "f") {
            ret.cssClasses = (ret.cssClasses || '') + ' unread';
          } else {
            ret.cssClasses = (ret.cssClasses || '') + ' read';
          }

          // highlight the top next task
          if (item.is_top_next_task) {
            ret.cssClasses = (ret.cssClasses || '') + ' top-next-task';
          }
        }

        return ret;
      }
    })(this.dataView.getItemMetadata)


    this.grid = new Slick.Grid(this.options.el, this.dataView, columns, options);
    this.grid.setSelectionModel(new Slick.RowSelectionModel());
    this.grid.registerPlugin(groupItemMetadataProvider);

    var columnpicker = new jobsworth.grids.ColumnPicker(columns, this.grid, options);

    // this line must be called before the lines below
    this.bind();

    // resize grid
    if (store.get('grid.height')) {
      $(this.options.el).height(store.get('grid.height'));
    }
    $(this.options.el).resizable({
      handles: 's',
      stop: function(event, ui) {
        store.set("grid.height", ui.size.height);
      }
    });

    this.dataView.beginUpdate();
    this.dataView.setItems(rows);
    this.dataView.endUpdate();
    this.grid.autosizeColumns();

    // group rows
    if (store.get('grid.groupBy')) {
      $("#groupBy select").val(store.get('grid.groupBy'));
    }
    $("#groupBy select").trigger("change");

    // select columns
    if (store.get('grid.Columns')) {
      var visibleColumns = [];
      var cols = store.get('grid.Columns');
      for(var i in cols) {
        for(var j in columns) {
          if (cols[i].name == columns[j].name) {
            columns[j].width = cols[i].width;
            visibleColumns.push(columns[j]);
          }
        }
      }
      this.grid.setColumns(visibleColumns);
    }
  }

  Grid.prototype.groupBy = function(column) {
    if (!column) {
      this.dataView.groupBy(null);
      return;
    }

    this.dataView.groupBy(
      column.field,
      function (g) {
        var total = 0;
        for(var i in g.rows){ total = total + g.rows[i].time; };
        var hours = Math.round(total/6)/10 + "hr";
        var text = column.name + ":  " + g.value + "  <span class='itemCount'>(" + g.count + " items, "+ hours + ")</span>";
        return text;
      },
      function (a, b) {
        return a.value > b.value;
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

  return Grid;
})(jQuery);
