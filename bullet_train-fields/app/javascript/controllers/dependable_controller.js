import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    dependentsSelector: String
  }

  updateDependents(event) {
    if (!this.hasDependents) { return false }
    
    this.dependents.forEach((dependent) => {
      dependent.dispatchEvent(new CustomEvent(`${this.identifier}:updated`, { detail: { event: event }, bubbles: true, cancelable: false }))
    })
  }
  
  get hasDependents() {
    return (this.dependents.length > 0)
  }
  
  get dependents() {
    if (!this.dependentsSelectorValue) { return [] }
    return document.querySelectorAll(this.dependentsSelectorValue)
  }
}
