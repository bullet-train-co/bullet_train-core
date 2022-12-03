import { Controller } from "@hotwired/stimulus"
require("intl-tel-input/build/css/intlTelInput.css");
import intlTelInput from 'intl-tel-input';

export default class extends Controller {
  static targets = [ "field" ]

  connect() {
    this.initPluginInstance()
  }

  disconnect() {
    this.teardownPluginInstance()
  }

  initPluginInstance() {
    let options = {
      hiddenInput: this.fieldTarget.dataset.method,
      customContainer: "w-full"
    }

    // TODO: add instructions on how to copy this asset into the application's assets path and write the meta tag into the head (via the engine?)
    const utilsScriptPath = metaContent("intl_tel_input_utils_path")
    if (utilsScriptPath) {
      options['utilsScript'] = utilsScriptPath
    }

    this.plugin = intlTelInput(this.fieldTarget, options);
  }

  teardownPluginInstance() {
    if (this.plugin === undefined) { return }

    // revert to original markup, remove any event listeners
    this.plugin.destroy()
  }
}

function metaContent (name) {
  const element = document.head.querySelector(`meta[name="${name}"]`)
  return element && element.content
}