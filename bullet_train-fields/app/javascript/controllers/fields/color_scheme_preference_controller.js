import { Controller } from "@hotwired/stimulus";

export default class extends Controller {

  connect() {
    this.updateRadioButtons()
  }

  updateRadioButtons() {
    const preference = window?.colorScheme?.preference
    this.radioButtonsWithValue(preference)?.checked = true
  }

  updateColorSchemePreference() {
    window?.colorScheme?.preference = this.radioButtons.find(button => button.checked)?.value
  }

  radioButtonWithValue(value) {
    return this.radioButtons.find(button => button.value === value)
  }

  get radioButtons() {
    return this.element.querySelectorAll('input[type="radio"]')
  }
}