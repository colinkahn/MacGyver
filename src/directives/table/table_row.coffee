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
      constructor: ->
        @rowCellMaps = {}

      repeatCells: ($scope, row, $element, sectionController) ->
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

        cells       = row.cells
        lastCellMap = @rowCellMaps[row.id] or {}
        nextCellMap = {}

        for cell in cells
          key         = cell.column.colName
          cellElement = lastCellMap[key]

          if cellElement
            nextCellMap[key] = cellElement
            delete lastCellMap[key]
            $element[0].appendChild cellElement[0]
          else
            nScope      = $scope.$new()
            nScope.cell = cell

            if linkerFn = linkerFactory cell
              clonedElement = linkerFn nScope, (clone) ->
                $element[0].appendChild clone[0]
                nextCellMap[key] = clone

        $el.remove() for key, $el of lastCellMap

        @rowCellMaps[row.id] = nextCellMap
]

angular.module("Mac").directive "macTableRow", [
  "MacTableRowController"
  (
    MacTableRowController
  ) ->
    require:    ["^macTable", "^macTableSection", "macTableRow"]
    controller: MacTableRowController
    transclude: "element"

    compile: (element, attr) ->
      ($scope, $element, $attr, controllers, $transclude) ->
        lastRowMap = {}

        $scope.$watch ->
          return unless controllers[1].section?.name?

          nextRowMap = {}

          for row in $scope.section.rows
            key = row.id
            li  = lastRowMap[key]

            if li
              $element.parent()[0].appendChild li[1][0]
              delete lastRowMap[key]
              nextRowMap[key] = li
            else
              nScope     = $scope.$new()
              nScope.row = row

              $transclude nScope, (clone) ->
                $element.parent()[0].appendChild clone[0]
                nextRowMap[key] = [nScope, clone]
                controllers[2].repeatCells nScope, row, clone, controllers[1]

          for key, li of lastRowMap
            li[0].$destroy()
            li[1].remove()
            delete controllers[2].rowCellMaps[key]

          lastRowMap = nextRowMap
          return JSON.stringify $scope.section.rows
]
