import { Controller } from "@hotwired/stimulus";

export default class extends Controller {

  connect() {
    this.updateRadioButtons()
    if (window.colorScheme === undefined) {
      this.hideOptions()
      console.warn(`window.colorScheme is not defined in the head. Update your local theme's light/layouts/_head.html.erb file.`)
    }
  }

  // this saves us from manually adding field target to options in the partial
  get radioButtons() {
    return Array.from(this.element.querySelectorAll('input[type="radio"]'))
  }

  updateRadioButtons() {
    if (!window?.colorScheme) { return }
    const preference = window?.colorScheme?.preference
    const button = this.radioButtonWithValue(preference)
    if (button) {
      button.checked = true
    }
  }

  updateColorSchemePreference() {
    if (!window?.colorScheme) { return }
    window.colorScheme.preference = this.radioButtons.find(button => button.checked)?.value
  }

  hideOptions() {
    this.element.hidden = true
  }

  radioButtonWithValue(value) {
    return this.radioButtons.find(button => button.value === value)
  }
}