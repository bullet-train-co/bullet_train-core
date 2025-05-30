import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="otp-response"
export default class extends Controller {
  static values = {
    otpRequired: Boolean,
  };

  connect() {
    document.querySelector("#step-1").classList.add("hidden");
    document.querySelector("#step-2").classList.remove("hidden");
    if (this.otpRequiredValue) {
      document.querySelector("#step-2-otp").classList.remove("hidden");
    }
    setTimeout(function() {
      document.querySelector("#user_password").focus();
      document.querySelector("#new_user").setAttribute('action', '/users/sign_in')
      document.querySelector("#new_user").setAttribute('data-remote', 'false');
    }, 1);
    this.element.remove();
  }
}
