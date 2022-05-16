import { identifierForContextKey } from "@hotwired/stimulus-webpack-helpers"

import ClipboardController from './clipboard_controller'
import FormController from './form_controller'
import MobileMenuController from './mobile_menu_controller'

export const controllerDefinitions = [
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
