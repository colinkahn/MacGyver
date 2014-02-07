angular.module("Mac").factory "TableSectionController", [ ->
  class TableSectionController
    constructor: (@section) ->
    # Value should probably be overridden by the user
    cellValue: (row, colName) -> @defaultCellValue(row, colName)
    # Since accessing a models key is useful
    # we keep this as a separate method
    defaultCellValue: (row, colName) -> row.model[colName]
]

angular.module("Mac").factory "TableRow", ->
  guid = 0

  class TableRow
    constructor: (@section, @model, @cells = [], @cellsMap = {}) ->
      @id = "$R#{guid++}"

    toJSON: ->
      cells: @cells

angular.module("Mac").factory "TableSection", ->
  guid = 0

  class TableSection
    constructor: (controller, @table, @name, @rows = []) ->
      @setController controller
      @id = "$S#{guid++}"

    setController: (controller) ->
      @ctrl = new controller(this)

    toJSON: ->
      rows: @rows

angular.module("Mac").factory "TableCell", ->
  class Cell
    constructor: (@row, @column) ->

    value: ->
      @row?.section?.ctrl.cellValue(@row, @column.colName)

    toJSON: ->
      value: @value()
      column: @column.colName

angular.module("Mac").factory "tableComponents", [
  "TableSectionController"
  "TableRow"
  "TableSection"
  "TableCell"
  (
    TableSectionController
    TableRow
    TableSection
    TableCell
  ) ->
    rowFactory: (section, model) ->
      return new TableRow(section, model)

    columnFactory: (colName) ->
      Column = (@colName) ->
      return new Column(colName)

    sectionFactory: (table, sectionName, controller = TableSectionController) ->
      return new TableSection(controller, table, sectionName)

    cellFactory: (row, column = {}) ->
      return new TableCell(row, column)
]

angular.module("Mac").factory "TableColumnsController", [
  "tableComponents"
  (
    tableComponents
  ) ->
    class ColumnsController
      constructor: (@table) ->

      blank: ->
        # Makes a blank object with our colNames as keys
        obj = {}
        for colName in @table.columnsOrder
          obj[colName] = null
        obj

      set: (columns) ->
        lastColumnsMap = @table.columnsMap
        nextColumnsMap = {}
        columnsArray   = []

        # Store the order
        for colName in columns
          column = lastColumnsMap[colName]

          if not column
            column = tableComponents.columnFactory colName

          nextColumnsMap[colName] = columnsArray[columnsArray.length] = column

        @table.columnsMap   = nextColumnsMap
        @table.columnsOrder = columns
        @table.columns      = columnsArray

        # Function might be better in table...
        for sectionName, section of @table.sections
          for row in section.rows
            cells = []
            for colName in @table.columnsOrder
              cell = row.cellsMap[colName]
              unless cell
                column = @table.columnsMap[colName]
                cell   = tableComponents.cellFactory(row, column)
              cells.push cell
            row.cells = cells
        columns = []
        for colName in @table.columnsOrder
          columns.push @table.columnsMap[colName]
        @table.columns = columns
]

angular.module("Mac").factory "TableRowsController", [
    "tableComponents"
    (
        tableComponents
    ) ->
      class RowsController
        constructor: (@table) ->

        make: (section, model) ->
          row = tableComponents.rowFactory(section, model)
          for colName in @table.columnsOrder
            column                = @table.columnsMap[colName]
            cell                  = tableComponents.cellFactory(row, column)
            row.cellsMap[colName] = cell
            row.cells.push cell
          row
]

angular.module("Mac").factory "Table", [
    "TableColumnsController"
    "TableRowsController"
    "tableComponents"
    (
        TableColumnsController
        TableRowsController
        tableComponents
    ) ->
      # Helper functions
      convertObjectModelsToArray = (models) ->
        if models and not angular.isArray models then [models] else models

      # The Table class
      class Table
        constructor: (columns = []) ->
          @sections           = {}
          @columns            = []
          @columnsOrder       = []
          @columnsMap         = {}
          @columnsCtrl        = new TableColumnsController(this)
          @rowsCtrl           = new TableRowsController(this)

          @columnsCtrl.set(columns)
          return

        makeSection: (sectionName) ->
          @sections[sectionName] =
            tableComponents.sectionFactory(this, sectionName)

        load: (sectionName, models, controller) ->
          if not @sections[sectionName]
            @makeSection sectionName

          @loadController sectionName, controller if controller
          @loadModels     sectionName, models     if models

        loadModels: (sectionName, models) ->
          orderedRows = []
          tableModels = []
          removedRows = []
          section     = @sections[sectionName]
          models      = convertObjectModelsToArray models

          for row in section.rows
            index = models.indexOf row.model
            if index is -1
              removedRows.push row
            else
              orderedRows[index] = row
              tableModels[index] = row.model

          for model, index in models when model not in tableModels
            orderedRows[index] = @rowsCtrl.make section, model

          # Overwrite old rows, rows not in orderedRows get GC'd?
          section.rows = orderedRows

          return [section.rows, removedRows]

        loadController: (sectionName, sectionController) ->
          @sections[sectionName].setController sectionController if sectionController

        blankRow: ->
          @columnsCtrl.blank()

        setColumns: (columns) ->
          for sectionName, section of @sections
            for row in section.rows
              for column in columns
                cell = row.cellMap[column]

        toJSON: ->
          sections: @sections
]
