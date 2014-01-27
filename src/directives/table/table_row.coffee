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
    transclude: "element"

    compile: (element, attr) ->
      ($scope, $element, $attr, controllers, $transclude) ->
        controllers[1].rowTemplate = $transclude
]
