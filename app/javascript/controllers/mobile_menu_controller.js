import { Controller } from "@hotwired/stimulus"
import { enter, leave } from "el-transition"

export default class extends Controller {
  static targets = [ "wrapper", "revealable"]
  static classes = [ "hidden" ] // necessary because we're always hiding the mobile menu on larger screens and this is the class used for only mobile screen sizes
  
  open() {
    this.showWrapper()
    this.revealableTargets.forEach(revealableTarget => {
      enter(revealableTarget)
    })
  }
  
  close() {
    Promise.all(
      this.revealableTargets.map(revealableTarget => {
        return leave(revealableTarget)
      })
    ).then(() => {
      this.hideWrapper()
    })
    
  }
  
  showWrapper() {
    this.wrapperTarget.classList.remove(this.hiddenClass)
  }
  
  hideWrapper() {
    this.wrapperTarget.classList.add(this.hiddenClass)
  }
}