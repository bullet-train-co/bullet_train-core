import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  updateFrameFromDependentSuperSelectValue(event) {
    const dependentSuperSelect = event?.detail?.event?.detail?.event?.target // original super select jQuery event
    
    const frame = this.element
    frame.src = this.constructNewUrlUpdatingField(dependentSuperSelect.name, dependentSuperSelect.value)
  }
  
  constructNewUrlUpdatingField(fieldName, fieldValue) {
    const url = new URL(window.location.href)
    url.searchParams.set(fieldName, fieldValue)
    
    return url.href
  }
}