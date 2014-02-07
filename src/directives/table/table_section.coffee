###
@chalk overview
@name Table Section 
@description
Main directive for registering table sections. Can optionally have 
macTableSectionModels, macTableSectionController, or macTableSectionBlankRow.

@dependencies
macTable
###


buildRows = (
  scope
  models
  sectionName
  sectionElement
  rowTemplate
  cellTemplates
  rowCellMaps
) ->
  [rows, removedRows] = scope.table.load sectionName, models

  for row in rows
    if row.$element
      sectionElement[0].appendChild row.$element[0]
    else
      row.$scope     = scope.$new()
      row.$scope.row = row

      rowTemplate row.$scope, (clone) =>
        sectionElement[0].appendChild clone[0]
        row.$element = clone

    # Gets the correct linker based on the cell column name
    linkerFactory = (cell) =>
      templateName =
        if cell?.column?.colName of cellTemplates
          cell.column.colName
        else
          "?"

      if template = cellTemplates[templateName]
        return template[1]

    # Repeat each cell

    cells       = row.cells
    lastCellMap = rowCellMaps[row.id] or {}
    nextCellMap = {}

    for cell in row.cells
      key         = cell.column.colName
      cellElement = lastCellMap[key]

      if cellElement
        nextCellMap[key] = cellElement
        delete lastCellMap[key]
        row.$element[0].appendChild cellElement[0]
      else
        nScope      = row.$scope.$new()
        nScope.cell = cell

        if linkerFn = linkerFactory cell
          clonedElement = linkerFn nScope, (clone) ->
            row.$element[0].appendChild clone[0]
            nextCellMap[key] = clone

    $el.remove() for key, $el of lastCellMap

    rowCellMaps[row.id] = nextCellMap

  for row in removedRows
    row.$element.remove()
    row.$scope.$destroy()
    delete rowCellMaps[row.id]

angular.module("Mac").directive "macTableSection", ->
  class MacTableSectionController
    constructor: (@scope, @attrs) ->
      @name          = null
      @section       = null
      @cellTemplates = {}
      @watchers      = {}

    registerWatcher: (directiveName, controller) ->
      @watchers[directiveName] = controller

    applyWatchers: ->
      for directiveName, controller of @watchers
        do (directiveName, controller) =>
          @attrs.$observe directiveName, (expression) =>
            controller.watch expression, @name

  # Config our directive object
  require:    ["^macTable", "macTableSection"]
  scope:      true
  controller: ["$scope", "$attrs", MacTableSectionController]

  compile: (element, attr, linker) ->
    ($scope, $element, $attr, controllers) ->
      # Track our section name / section data
      $attr.$observe "macTableSection", (sectionName) ->
        return unless sectionName
        controllers[1].name = sectionName

        # Watch our table
        $scope.$watch "table", (table) ->
          return unless table

          # Watch for our section to be created
          $scope.$watch "table.sections.#{sectionName}", (section) ->
            $scope.section = controllers[1].section = $scope.table.sections[sectionName]

          # Call the watch method on any directives that have registered
          controllers[1].applyWatchers()

###
@chalk overview
@name Table Section Blank Row
@description
Inserts a blank row with keys matching those of the tables columns.

@dependencies
macTable, macTableSection
###

angular.module("Mac").directive "macTableSectionBlankRow", ->
  class MacTableSectionBlankRowCtrl
    constructor: (@scope, @element) ->

    watch: (expression, sectionName) ->
      # We want to wait for another section to be loaded before we create our
      # blank row, this ensures we actually have column names to work with
      sectionToWaitOn = expression or "body"
      
      killWatcher = @scope.$watch "table.sections.#{sectionToWaitOn}.rows", (rows) =>
        return unless rows
        killWatcher()
        model = @scope.table.blankRow()

        @scope.$watch =>
          # We do this in two steps to avoid clobbering our columns when
          # the table has dynamic columns

          @rowCellMaps = {} unless @rowCellMaps

          buildRows(
            @scope
            [model]
            sectionName
            @element
            @rowTemplate
            @cellTemplates
            @rowCellMaps
          )
          return JSON.stringify @scope.table.columnsOrder


  require:    ["^macTable", "macTableSection", "macTableSectionBlankRow"]
  controller: ["$scope", "$element", MacTableSectionBlankRowCtrl]

  link: ($scope, $element, $attrs, controllers) ->
    controllers[2].cellTemplates = controllers[1].cellTemplates
    controllers[2].rowTemplate   = controllers[1].rowTemplate
    controllers[1].registerWatcher "macTableSectionBlankRow", controllers[2]

###
@chalk overview
@name Table Section Models
@description
Watches a models expression and loads them into the section

@dependencies
macTable, macTableSection
###

angular.module("Mac").directive "macTableSectionModels", ["$parse", ($parse) ->
  class MacTableSectionModelsCtrl
    constructor: (@scope, @element) ->

    watch: (expression, sectionName) ->
      lastStringified = ""

      @scope.$watch =>
        models = $parse(expression)(@scope)
        return unless angular.isArray models

        @rowCellMaps = {} unless @rowCellMaps

        buildRows(
          @scope
          models
          sectionName
          @element
          @rowTemplate
          @cellTemplates
          @rowCellMaps
        )

        return JSON.stringify @scope.table.sections[sectionName].rows

  require:    ["^macTable", "macTableSection", "macTableSectionModels"]
  controller: ["$scope", "$element", MacTableSectionModelsCtrl]

  link: ($scope, $element, $attrs, controllers) ->
    controllers[2].cellTemplates = controllers[1].cellTemplates
    controllers[2].rowTemplate   = controllers[1].rowTemplate
    controllers[1].registerWatcher "macTableSectionModels", controllers[2]
]

###
@chalk overview
@name Table Section Controller
@description
Watches a controller expression and loads the controller into the section

@dependencies
macTable, macTableSection
###

angular.module("Mac").directive "macTableSectionController", ->
  class MacTableSectionControllerCtrl
    constructor: (@scope) ->

    watch: (expression, sectionName) ->
      @scope.$watch expression, (controller) =>
        return unless controller

        @controller = controller
        @scope.table.load sectionName, null, controller

  require:    ["^macTable", "macTableSection", "macTableSectionController"]
  controller: ["$scope", MacTableSectionControllerCtrl]

  link: ($scope, $element, $attrs, controllers) ->
    controllers[1].registerWatcher "macTableSectionController", controllers[2]
