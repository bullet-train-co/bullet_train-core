import { Controller } from "@hotwired/stimulus"

// TODO Some of this feels really specific to the conversation messages form. Should we rename this controller?
export default class extends Controller {
  static targets = ['trixField', 'scroll']

  resetOnSuccess(e){
    if(e.detail.success) {
      e.target.reset();
    }
  }

  stripTrix(){
    this.trixFieldTargets.forEach(element => {
      this.removeTrailingNewlines(element.editor)
      this.removeTrailingWhitespace(element.editor)
      // When doing this as part of the form submission, Trix does not update the input element's value attribute fast enough.
      // In order to submit the stripped value, we manually update it here to fix the race condition
      element.parentElement.querySelector("input").value = element.innerHTML
    })
  }

  submitOnReturn(e) {
    if((e.metaKey || e.ctrlKey) &&  e.keyCode == 13) {
      e.preventDefault();
      let form = e.target.closest("form")
      this.submitForm(form)
    }
  }

  removeTrailingNewlines = (trixEditor) => {
    if (trixEditor.element.innerHTML.match(/<br><\/div>$/)) {
      trixEditor.element.innerHTML = trixEditor.element.innerHTML.slice(0, -10) + "</div>"
      this.removeTrailingNewlines(trixEditor)
    }
  }

  removeTrailingWhitespace = (trixEditor) => {
    if (trixEditor.element.innerHTML.match(/&nbsp;<\/div>$/)) {
      trixEditor.element.innerHTML = trixEditor.element.innerHTML.slice(0, -12) + "</div>"
      this.removeTrailingWhitespace(trixEditor)
    } else if (trixEditor.element.innerHTML.match(/&nbsp; <\/div>$/)) {
      trixEditor.element.innerHTML = trixEditor.element.innerHTML.slice(0, -13) + "</div>"
      this.removeTrailingWhitespace(trixEditor)
    }
  }

  submitForm(form) {
    // Right now, Safari and IE don't support the requestSubmit method which is required for Turbo
    // Doing form.submit() doesn't actually fire the submit event which Turbo needs
    if (form.requestSubmit) {
      form.requestSubmit()
    } else {
      form.querySelector("[type=submit]").click()
    }
  }
}
