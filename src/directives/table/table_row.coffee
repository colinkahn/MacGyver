###
@chalk overview
@name Table Row
@description
Directive initializing a table row for cell templates to be registered under

@dependencies
macTable, macTableSection
###

angular.module("Mac").directive "macTableRow", [
  ->
    require:    ["^macTable", "^macTableSection"]
    controller: ->
    terminal:   true
    transclude: "element"
    priority:   1000

    compile: (element, attr) ->
      ($scope, $element, $attr, controllers, $transclude) ->
        controllers[1].rowTemplate = $transclude
]
