import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "field" ]
  static values = {
    valuesStore: { type: Object, default: {} },
    loading: { type: Boolean, default: false }
  }
  static classes = [ "loading" ]
  
  updateFrameFromDependableField(event) {
    const field = event?.detail?.event?.detail?.event?.target || // super select nests its original jQuery event, contains <select> target
                  event?.detail?.event?.target || // dependable_controller will include the original event in detail
                  event?.target // maybe it was fired straight from the field
    
    if (!field) { return }
    
    this.storeFieldValues()
    
    this.loadingValue = true
    this.disableFieldInputWhileRefreshing()
    
    const frame = this.element
    frame.src = this.constructNewUrlUpdatingField(field.name, field.value)
  }
  
  finishFrameUpdate(event) {
    if (event.target !== this.element) { return }
    
    this.restoreFieldValues()
    this.loadingValue = false
  }
  
  constructNewUrlUpdatingField(fieldName, fieldValue) {
    const url = new URL(window.location.href)
    url.searchParams.set(fieldName, fieldValue)
    
    return url.href
  }
  
  disableFieldInputWhileRefreshing() {
    this.fieldTargets.forEach(field => field.disabled = true )
  }
  
  loadingValueChanged() {
    if (!this.hasLoadingClass) { return }
    this.element.classList.toggle(...this.loadingClasses, this.loadingValue)
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
      field.dispatchEvent(new Event('change')) // ensures cascading effects, including super-select validating against valid options
    })
    
    this.valuesStoreValue = {}
  }
}