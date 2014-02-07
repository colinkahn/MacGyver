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

angular.module("Mac").factory "Table", [
    "tableComponents"
    (tableComponents) ->

      convertObjectModelsToArray = (models) ->
        if models and not angular.isArray models then [models] else models

      class Table
        constructor: (columns = []) ->
          @sections           = {}
          @columns            = []
          @columnsOrder       = []
          @columnsMap         = {}

          @loadColumns(columns)
          return

        makeSection: (sectionName) ->
          @sections[sectionName] =
            tableComponents.sectionFactory(this, sectionName)

        load: (sectionName, models, controller) ->
          if not @sections[sectionName]
            @makeSection sectionName

          @loadController sectionName, controller if controller
          @loadModels     sectionName, models     if models

          return this

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
            orderedRows[index] = @newRow section, model

          # Overwrite old rows, rows not in orderedRows get GC'd?
          section.rows        = orderedRows
          section.removedRows = removedRows

        loadColumns: (columns = @columnsOrder) ->
          lastColumnsMap = @columnsMap
          nextColumnsMap = {}
          columnsArray   = []

          for colName in columns
            column = lastColumnsMap[colName]

            if not column
              column = tableComponents.columnFactory colName

            nextColumnsMap[colName] = columnsArray[columnsArray.length] = column

          @columnsMap   = nextColumnsMap
          @columnsOrder = columns
          @columns      = columnsArray

          for sectionName, section of @sections
            for row in section.rows
              cells = []
              for colName in @columnsOrder
                cell = row.cellsMap[colName]
                unless cell
                  column = @columnsMap[colName]
                  cell   = tableComponents.cellFactory(row, column)
                cells.push cell
              row.cells = cells

          return this

        loadController: (sectionName, sectionController) ->
          @sections[sectionName].setController sectionController if sectionController

        blankRow: ->
          @columnsOrder.reduce (row, colName) ->
            row[colName] = null
            return row
          , {}

        newRow: (section, model) ->
          row = tableComponents.rowFactory(section, model)
          for colName in @columnsOrder
            column                = @columnsMap[colName]
            cell                  = tableComponents.cellFactory(row, column)
            row.cellsMap[colName] = cell
            row.cells.push cell
          row

        toJSON: ->
          sections: @sections
]
