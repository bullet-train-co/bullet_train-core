import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = [ "button", "idsHiddenField", "allHiddenField" ]
  static classes = [ "hidden" ]
  static values = {
    buttonIfAll: String,
    buttonIfIds: String,
    ids: Array,
    all: Boolean,
    objectName: String,
    idsFieldName: String,
    allFieldName: String
  }

  connect() {
    this.updateAvailability()
  }

  updateFormAndSubmit(event) {
    this.recreateIdsHiddenFields()
    this.createOrUpdateAllField()
    return true
  }

  updateIds(event) {
    if (event?.detail?.ids) {
      this.idsValue = event.detail.ids
      this.allValue = event.detail.all
    }

    this.updateAvailability()
    this.updateButtonLabel()
  }

  updateAvailability() {
    this.element.classList.toggle(this.hiddenClass, this.idsValue.length === 0)
  }

  updateButtonLabel() {
    let label = this.buttonIfAllValue
    if (this.idsValue.length && this.allValue === false) {
      label = this.buttonIfIdsValue.replace('{num}', this.idsValue.length)
    }

    switch (this.buttonTarget.tagName) {
      case 'INPUT': this.buttonTarget.value = label; break;
      default: this.buttonTarget.textContent = label; break;
    }
  }

  recreateIdsHiddenFields() {
    this.removeIdsHiddenFields()
    this.createIdsHiddenFields()
  }

  removeIdsHiddenFields() {
    this.idsHiddenFieldTargets.forEach(field => {
      this.element.removeChild(field)
    })
  }

  createIdsHiddenFields() {
    this.idsValue.forEach(id => {
      let field = document.createElement('input')
      field.type = 'hidden'
      field.name = `${this.objectNameValue}[${this.idsFieldNameValue}][]`
      field.value = id
      this.element.appendChild(field)
    })
  }

  createOrUpdateAllField() {
    if (this.hasAllHiddenFieldTarget) {
      this.allHiddenFieldTarget.value = this.allValue? 'true': 'false'
    } else {
      this.createAllField()
    }
  }

  createAllField() {
    let field = document.createElement('input')
    field.type = 'hidden'
    field.name = `${this.objectNameValue}[${this.allFieldNameValue}]`
    field.value = this.allValue? 'true': 'false'
    this.element.appendChild(field)
  }
}