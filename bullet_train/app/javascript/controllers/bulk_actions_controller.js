import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = [ "checkbox", "selectAllCheckbox", "action", "selectableToggle", "selectAllLabel" ]
  static classes = [ "selectableAvailable", "selectable" ]
  static values = {
    selectable: Boolean
  }

  connect() {
    this.element.classList.add(this.selectableAvailableClass)
  }

  toggleSelectable() {
    this.selectableValue = !this.selectableValue
  }

  updateSelectedIds() {
    this.updateActions()
    this.updateSelectAllCheckbox()
  }

  updateActions() {
    this.actionTargets.forEach(actionTarget => {
      actionTarget.dispatchEvent(new CustomEvent('update-ids', { detail: {
        ids: this.selectedIds,
        all: this.allSelected
      }}))
    })
  }

  selectAllOrNone(event) {
    if (this.allSelected) {
      this.selectNone()
    } else {
      this.selectAll()
    }
    this.updateSelectAllCheckbox()
  }

  selectAll() {
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = true
    })
    this.updateActions()
  }

  selectNone() {
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = false
    })
    this.updateActions()
  }

  updateSelectAllCheckbox() {
    let checkbox = this.selectAllCheckboxTarget
    let label = this.selectAllLabelTarget

    if (this.allSelected) {
      checkbox.checked = true
      checkbox.indeterminate = false
      label.dispatchEvent(new CustomEvent('toggle', { detail: { useAlternate: true }} ))
    } else if (this.selectedIds.length > 0) {
      checkbox.indeterminate = true
      label.dispatchEvent(new CustomEvent('toggle', { detail: { useAlternate: false }} ))
    } else {
      checkbox.checked = false
      checkbox.indeterminate = false
      label.dispatchEvent(new CustomEvent('toggle', { detail: { useAlternate: false }} ))
    }
  }

  selectableValueChanged() {
    this.element.classList.toggle(this.selectableClass, this.selectableValue)
    this.updateToggleLabel()
  }

  updateToggleLabel() {
    if (!this.hasSelectableToggleTarget) { return }
    this.selectableToggleTarget.dispatchEvent(new CustomEvent('toggle', { detail: { useAlternate: this.selectableValue }} ))
  }

  get selectedIds() {
    let ids = []
    this.checkboxTargets.forEach(checkbox => {
      if (checkbox.checked) {
        ids.push(checkbox.value)
      }
    })
    return ids
  }

  get allSelected() {
    return this.selectedIds.length === this.checkboxTargets.length
  }
}