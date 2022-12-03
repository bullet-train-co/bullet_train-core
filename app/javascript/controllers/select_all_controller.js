import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [ "checkbox", "toggleCheckbox", "toggleLabel", "wrapper" ]
  static classes = [ "unavailable" ]
  
  connect() {
    this.enableSelectAll()
  }
  
  enableSelectAll() {
    if (!this.hasWrapperTarget) { return }
    if (!this.hasUnavailableClass) { return }
    
    this.wrapperTarget.classList.remove(this.unavailableClass)
    this.updateToggle()
  }
  
  selectAllOrNone(event) {
    event.preventDefault()
    event.stopPropagation()
    if (this.allSelected) {
      this.selectNone()
    } else {
      this.selectAll()
    }
    this.updateToggle()
    this.dispatch('toggled')
  }
  
  selectAll() {
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = true
    })
  }
  
  selectNone() {
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = false
    })
  }
  
  updateToggle() {
    let checkbox = this.toggleCheckboxTarget
    let useAlternateLabel = false
    
    if (this.allSelected) {
      if (checkbox) {
        checkbox.checked = true
        checkbox.indeterminate = false
      }
      useAlternateLabel = true
    } else if (this.selectedValues.length > 0) {
      if (checkbox) {
        checkbox.indeterminate = true
      }
    } else {
      if (checkbox) {
        checkbox.checked = false
        checkbox.indeterminate = false
      }
    }
    
    if (this.hasToggleLabelTarget) {
      this.toggleLabelTarget.dispatchEvent(new CustomEvent(`${this.identifier}:toggle-select-all-label`, { detail: { useAlternate: useAlternateLabel }} ))
    }
  }
  
  get selectedValues() {
    let values = []
    this.checkboxTargets.forEach(checkbox => {
      if (checkbox.checked) {
        values.push(checkbox.value)
      }
    })
    return values
  }
  
  get allSelected() {
    return this.selectedValues.length === this.checkboxTargets.length
  }
}
