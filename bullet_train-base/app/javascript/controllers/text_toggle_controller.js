import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    label: String,
    labelAlternate: String,
    useAlternate: Boolean,
  }

  connect() {
    this.updateLabel()
  }

  toggle(event) {
    if (undefined !== event?.detail?.useAlternate) {
      this.useAlternateValue = event.detail.useAlternate
    } else {
      this.useAlternateValue = !this.useAlternateValue
    }
  }

  useAlternateValueChanged() {
    this.updateLabel()
  }

  updateLabel() {
    if (!this.hasLabelValue || !this.hasLabelAlternateValue || !this.hasUseAlternateValue) {
      return
    }

    this.element.textContent = this.useAlternateValue === true ? this.labelAlternateValue : this.labelValue
  }
}
