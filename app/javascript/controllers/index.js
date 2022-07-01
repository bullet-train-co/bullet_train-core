import { identifierForContextKey } from "@hotwired/stimulus-webpack-helpers"

import BulkActionFormController from './bulk_action_form_controller'
import BulkActionsController from './bulk_actions_controller'
import ClipboardController from './clipboard_controller'
import FormController from './form_controller'
import MobileMenuController from './mobile_menu_controller'

export const controllerDefinitions = [
  [BulkActionFormController, 'bulk_action_form_controller.js'],
  [BulkActionsController, 'bulk_actions_controller.js'],
  [ClipboardController, 'clipboard_controller.js'],
  [FormController, 'form_controller.js'],
  [MobileMenuController, 'mobile_menu_controller.js'],
].map(function(d) {
  const key = d[1]
  const controller = d[0]
  return {
    identifier: identifierForContextKey(key),
    controllerConstructor: controller
  }
})
