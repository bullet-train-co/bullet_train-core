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
    frame.src = this.constructNewUrlUpdatingField(field)
  }

  finishFrameUpdate(event) {
    if (event.target !== this.element) { return }

    this.restoreFieldValues()
    this.loadingValue = false
  }

  constructNewUrlUpdatingField(field) {
    const url = new URL(this.currentUrl)
    const form = field.form
    const formData = form ? new FormData(form) : {}
    
    if ((field.type === "checkbox" || field.type === "select-multiple") && field.name.endsWith("[]")) {
      url.searchParams.delete(field.name)
      formData.getAll(field.name).forEach(value => {
        url.searchParams.append(field.name, value)
      })
    } else {
      url.searchParams.set(field.name, this.getValueForField(field))
    }

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
      storeUpdate[field.name] = this.getValueForField(field)
      this.valuesStoreValue = Object.assign(this.valuesStoreValue, storeUpdate)
    })
  }

  restoreFieldValues() {
    this.fieldTargets.forEach(field => {
      const storedValue = this.valuesStoreValue[field.name]
      if (storedValue === undefined) { return }
      this.setValueForField(field, storedValue)
      field.dispatchEvent(new Event('change')) // ensures cascading effects, including super-select validating against valid options
    })

    this.valuesStoreValue = {}
  }

  getValueForField(field) {
    if (field.type === "checkbox") {
      return field.checked
    }

    return field.value
  }

  setValueForField(field, value) {
    if (field.type === "checkbox") {
      field.checked = value
    }

    field.value = value
  }

  get currentUrl() {
    const turboFrameWithUrl = this.element.closest("turbo-frame[src]")
    return turboFrameWithUrl ? turboFrameWithUrl.src : window.location.href
  }
}
