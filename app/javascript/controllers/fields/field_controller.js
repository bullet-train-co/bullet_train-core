import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "field" ]
  static values = {
    original: String,
    dirty: Boolean
  }
  
  connect() {
    this.recordOriginal()
  }
  
  recordOriginal() {
    if (!this.hasOriginalValue) {
      this.originalValue = this.value
    }
    this.dispatch('original-recorded', {
      detail: { originalValue: this.originalValue },
      target: this.field
    })
  }
  
  revert(event) {
    if (this.hasOriginalValue) {
      this.value = this.originalValue
    }
    this.dispatch('reverted')
  }
  
  get field() {
    if (this.hasFieldTarget) {
      return this.fieldTarget
    }
    return this.element
  }
  
  get value() {
    switch (this.field.type) {
      case "checkbox":
        return this.field.checked
    }
    
    return this.field.value
  }
  
  set value(newValue) {
    switch (this.field.type) {
      case "checkbox":
        this.field.checked = (newValue === "true" || newValue === true)
        break
      default:
        this.field.value = newValue
        break
    }
  }
}