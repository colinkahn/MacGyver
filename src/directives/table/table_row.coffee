###
@chalk overview
@name Table Row
@description
Directive initializing a table row for cell templates to be registered under

@dependencies
macTable, macTableSection
###

angular.module("Mac").factory "MacTableRowController", [
  "directiveHelpers"
  (
    directiveHelpers
  ) ->
    class MacTableRowController
      repeatCells: (cells, rowElement, sectionController) ->
        # Gets the correct linker based on the cell column name
        linkerFactory = (cell) ->
          templateName =
            if cell.column.colName of sectionController.cellTemplates
              cell.column.colName
            else
              "?"

          if template = sectionController.cellTemplates[templateName]
            return template[1]

        # A condensed version of ng-repeat
        # I doubt we'll need animations here, so they're left out

        $scope         = rowElement.scope()
        lastCellMap    = @lastCellMap or {}
        nextCellMap    = {}
        cursor         = null

        for cell in cells
          key         = cell.column.colName
          cellElement = lastCellMap[key]

          if cellElement
            nextCellMap[key] = cellElement
            delete lastCellMap[key]
            rowElement[0].appendChild cellElement[0]
          else
            nScope      = $scope.$new()
            nScope.cell = cell

            if linkerFn = linkerFactory cell
              clonedElement = linkerFn nScope, (clone) ->
                rowElement[0].appendChild clone[0]
                nextCellMap[key] = clone

        for key, element of lastCellMap
          element.remove()

        @lastCellMap = nextCellMap
]

angular.module("Mac").directive "macTableRow", [
  "MacTableRowController"
  (
    MacTableRowController
  ) ->
    require:    ["^macTable", "^macTableSection", "macTableRow"]
    controller: MacTableRowController

    compile: (element, attr) ->
      ($scope, $element, $attr, controllers) ->
        # Watch our rows cells for changes...
        $scope.$watch "row.cells", (cells) ->
          # We might end up with a case were our section hasn't been added yet
          # if so return without anymore processing
          return unless controllers[1].section?.name?
          controllers[2].repeatCells cells, $element, controllers[1]
]
