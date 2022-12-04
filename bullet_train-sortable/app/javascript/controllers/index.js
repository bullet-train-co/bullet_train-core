import { identifierForContextKey } from "@hotwired/stimulus-webpack-helpers"

import SortableController from './sortable_controller'

export const controllerDefinitions = [
  [SortableController, 'sortable_controller.js']
].map(function(d) {
  const key = d[1]
  const controller = d[0]
  return {
    identifier: identifierForContextKey(key),
    controllerConstructor: controller
  }
})

export {
  SortableController
}