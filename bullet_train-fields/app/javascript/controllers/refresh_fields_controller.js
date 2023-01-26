import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "field" ]
  static values = {
    valuesStore: {
      type: Object,
      default: {}
    }
  }
  
  updateFrameFromDependentSuperSelectValue(event) {
    const dependentSuperSelect = event?.detail?.event?.detail?.event?.target // original super select jQuery event
    
    this.storeFieldValues()
    
    const frame = this.element
    frame.src = this.constructNewUrlUpdatingField(dependentSuperSelect.name, dependentSuperSelect.value)
  }
  
  finishFrameUpdate(event) {
    if (event.target !== this.element) { return }
    this.restoreFieldValues()
  }
  
  constructNewUrlUpdatingField(fieldName, fieldValue) {
    const url = new URL(window.location.href)
    url.searchParams.set(fieldName, fieldValue)
    
    return url.href
  }
  
  storeFieldValues() {
    this.fieldTargets.forEach(field => {
      let storeUpdate = {}
      storeUpdate[field.name] = field.value
      this.valuesStoreValue = Object.assign(this.valuesStoreValue, storeUpdate)
    })
  }
  
  restoreFieldValues() {
    this.fieldTargets.forEach(field => {
      const storedValue = this.valuesStoreValue[field.name]
      if (storedValue === undefined) { return }
      field.value = storedValue
    })
    
    this.valuesStoreValue = {}
  }
}